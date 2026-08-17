---
name: codex-watch-pr
description: >-
  Wait for a pull request's checks to settle in one long-running command, then report passed, skipped, and failed jobs with run links. Use whenever the user asks Codex to watch a pull request or wait for CI, and whenever another workflow needs the result before continuing.
---

# Watch a pull request

Use the pull request number in the task, or omit it for the current branch's open pull request. Start one blocking command with a long yield:

```bash
bash .agents/skills/codex-watch-pr/scripts/watch-checks.sh <number>
```

Set the execution yield to at most 30 seconds. If it returns a running session, continue it with `write_stdin` using empty input and a wait of up to 300 seconds. Keep waiting on that same session. Don't start another watcher or poll `gh pr checks` between waits. Send a concise progress update at least once a minute while checks remain pending.

The script emits `PASS`, `SKIP`, and `FAIL` events and closes with `ALL GREEN`, `FAILED`, `TIMEOUT`, or `NO CHECKS`. Exit codes are 0 for green, 1 for failures, and 2 for timeout or absent checks. Timeout and absent checks are inconclusive, not failures. Report the pull request, failed jobs, and printed run links. Invoke `codex-fix-pr` only when the caller requested remediation.

`PR_CHECKS_TIMEOUT` and `PR_CHECKS_INTERVAL` override the script bounds in seconds.
