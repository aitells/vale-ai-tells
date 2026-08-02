---
name: watch-pr
license: Apache-2.0
description: >-
  Wait for a pull request's checks to settle, then report what passed and what failed. Blocks in a single call rather than polling, so a wait costs one turn instead of one per look. Use this whenever the user asks to watch a pull request or wait on CI, and whenever a workflow needs that answer before it can go on.
hooks:
  PreToolUse:
    - matcher: Bash
      hooks:
        - type: command
          command: "${CLAUDE_PROJECT_DIR}/.claude/skills/watch-pr/scripts/guard-watch.sh"
---

# Watch a pull request

Wait for the checks on a pull request to settle, then say what happened. This skill ends when the checks stop moving. Fixing what failed belongs to `fix-pr`, and merging belongs to `merge-pr`.

A guard hook runs alongside and refuses the watching forms this skill wraps, so a hand-rolled poll can't quietly replace the watcher. A plain `gh pr checks` for a one-off look stays open.

## Which pull request

`$ARGUMENTS` names the pull request number when the caller knows it. An empty value means whatever is open for the current branch.

## Step 1: watch

Arm the watcher through the `Monitor` tool, which turns each line the script prints into a notification:

```text
Monitor({
  command: "bash .claude/skills/watch-pr/scripts/watch-checks.sh <number>",
  description: "checks on pull request <number>",
  timeout_ms: 1800000,
  persistent: false,
})
```

Omit the number to use the current branch's open pull request.

`Monitor` is the right tool rather than a blocking call, because the script emits one line per check the moment that check settles. A failure arrives while the slower jobs are still going, so the diagnosis starts earlier and no turn goes to waiting. The script exits once nothing is pending, which ends the watch by itself.

Never poll `gh pr checks` in a loop of your own. Each look costs a turn and reports a state that has already moved on.

The lines to expect:

- `WATCHING #<number>` once, at the start
- `PASS <job>`, `SKIP <job>`, or `FAIL <job> <run link>`, one per check as it settles
- `ALL GREEN #<number>`, `FAILED #<number> with N failing check(s)`, or `TIMEOUT #<number>` to close

Running the same command through `Bash` also works and blocks until the same ending, with the exit code carrying the outcome: `0` all passed, `1` something failed, `2` the wait ran out. Prefer `Monitor`. Reach for the blocking form only where the next step can't start until the answer arrives.

Override the bounds through the environment when a run is unusually slow. `PR_CHECKS_TIMEOUT` sets the whole wait and `PR_CHECKS_INTERVAL` the poll spacing, both in seconds. Keep `timeout_ms` past `PR_CHECKS_TIMEOUT` so the script reports its own timeout rather than dying at the tool's.

## Step 2: report

Say which checks failed and hand back. Name the pull request, the failing jobs, and the run links the script printed.

Where the caller asked only to watch, stop here. Where the caller asked for a fix, invoke `fix-pr` with the same number. That skill reads the logs and names the local recipe reproducing each failure.

A timeout isn't a failure. Say the checks were still running, give the elapsed bound, and let the caller decide whether to wait again.

## Preconditions

- `gh` installed and authenticated
- a pull request open for the branch, or a number in `$ARGUMENTS`

The script checks both and stops with a plain message when either is missing.
