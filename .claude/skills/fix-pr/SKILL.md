---
name: fix-pr
license: Apache-2.0
description: >-
  Diagnose the failing checks on a pull request and fix them. One call reads the failing logs and names the local recipe that reproduces each failure, so the work starts from a reproduction rather than a guess. The correction goes through the commit skill. Use this whenever a pull request is red, whenever the user asks to fix CI, and whenever watch-pr comes back with failures.
hooks:
  PreToolUse:
    - matcher: Write|Edit
      hooks:
        - type: command
          command: "${CLAUDE_PROJECT_DIR}/.claude/skills/write-pr-description/scripts/guard-draft.sh"
    - matcher: Bash
      hooks:
        - type: command
          command: "${CLAUDE_PROJECT_DIR}/.claude/skills/fix-pr/scripts/guard-fix.sh"
---

# Fix a failing pull request

Take a red pull request and make the checks pass. This skill ends when the branch carries a fix and the push has gone out. Confirming the result belongs to `watch-pr`, and merging belongs to `merge-pr`.

A guard hook runs alongside. It refuses a log sweep that goes around the diagnosis below, while leaving one job's full log open to read, because that's the real next step once the printed tail runs short.

## Which pull request

`$ARGUMENTS` names the pull request number when the caller knows it. An empty value means whatever is open for the current branch.

## Step 0: open the task list

Create these with `TaskCreate`, then move each through `in_progress` and `completed`.

1. Diagnose the failures
2. Reproduce each one locally
3. Fix the cause
4. Commit through the commit skill
5. Bring the description forward
6. Push and hand back

## Step 1: diagnose

```text
bash .claude/skills/fix-pr/scripts/diagnose.sh <number>
```

One call gets the failing jobs, the tail of each failing step's log, and the local recipe covering the same ground. Read that output before running anything else. Going straight to `gh run view` repeats work the script already did.

The script also compares the local checkout against the commit CI tested. Stop when it reports a mismatch. The logs then describe code this worktree no longer carries, so a fix aimed at them reaches the wrong revision. Check out the branch the pull request names, or pull it forward, and diagnose again.

## Step 2: reproduce

Run the recipe the script named for each failure. Reproducing first is what separates a fix from a guess.

The mapping from job name to recipe is a guess, so treat a recipe that passes locally as a signal rather than a contradiction. Look for the explanation among these:

- The job runs something the recipe doesn't. Read the workflow.
- The failure depends on the environment, such as a pinned tool version or a container image the worktree isn't running.
- The failure is a flake, which makes the run worth repeating before anything changes.

Say which one applies rather than editing until the symptom moves.

## Step 3: fix the cause

Change what made the check fail, and nothing else. A red pull request is a poor moment for adjacent cleanup: it widens the diff a reviewer already has questions about, and it hides the fix inside unrelated edits.

Where a lint gate failed, the finding names the file and the line, and often the replacement too. Apply it exactly. Where a test failed, read the assertion before changing either side, because a test that caught a real defect deserves the fix on the other side.

Never silence a gate to make it pass. Excluding a path changes the project's standards, and so does a new rule exception or a lowered threshold. Any of those goes to the operator as a proposal rather than into the commit.

Re-run the reproducer until it passes.

## Step 4: commit

How the fix lands is the caller's choice. `$ARGUMENTS` carries it when `pr` routed here, and where it doesn't, ask before committing with `AskUserQuestion`: `question` set to `How should this fix land?`, `header` set to `Fixes`, `multiSelect` set to `false`, and these options:

| Label | Description |
| --- | --- |
| `Separate commit` | `The fix lands as its own commit. History keeps the record of what broke.` |
| `Amend and force-push` | `The fix folds into the commit that caused it, pushed with --force-with-lease.` |

Either way, the `commit` skill takes it from there, and it owns the message and the review and the gates exactly as it always does. One thing changes for an amend: pass `--amend` after the repository root when invoking `review-commit-message`, so it reads `git diff --cached HEAD~1` rather than the staged delta. Skip that and the reviewer judges a whole message against a partial diff, returning findings that look certain and are wrong. Where the fix splits into unrelated groups the commit skill says so and takes them one at a time, which suits a separate commit better than an amend.

## Step 5: bring the description forward

The description lives on GitHub at this point, and often nothing sits on disk. Fetch it back before revising it:

```text
bash .claude/skills/fix-pr/scripts/populate-description.sh <number>
```

That rebuilds `PR_AGENTDESC.md` from what the pull request currently says, reassembling the frontmatter from the properties it carries. It refuses to overwrite an existing draft without `--force`, because a `pr` workflow further up the stack may have one in flight.

A fix changes what the branch does, so the published description now describes a branch that has moved. Where the change is worth a reader's attention, invoke `write-pr-description` with the repository root and a note saying which commits arrived since the last publish.

Then invoke `review-pr-description` and loop on its verdict the same way the `pr` skill does, bounded at three rounds. Publish the result with `bash .claude/skills/pr/scripts/create-pr.sh`, which updates the open pull request rather than opening another.

Skip this where the fix left the description accurate. A typo in a lint rule rarely changes what the branch is for. Say which way you judged it.

Don't edit `PR_AGENTDESC.md` here. A guard hook refuses it, and the writer owes the validator a clean run that hand-editing skips.

## Step 6: push and hand back

A separate commit pushes normally:

```text
git push origin HEAD
```

An amend rewrote the branch, so it needs the lease:

```text
git push --force-with-lease origin HEAD
```

Never a bare `--force`. A guard hook refuses it, because the lease is the difference between replacing your own commit and discarding whatever arrived while you worked.

Report what failed, what caused it, and what the fix changed. Then say the checks are running again.

Where the caller asked for a fix and nothing more, stop here. Where the caller asked to see it through, invoke `watch-pr` with the same number and repeat from step 1 on a fresh failure.

Bound the loop. After three rounds on the same check, stop, then report what each attempt changed and why the check still fails. A fourth attempt at the same shape of fix is rarely the one that works.

## Preconditions

- `gh` installed and authenticated
- the pull request's branch checked out, so a fix reaches the code CI tested
- the `commit` skill deployed alongside this one
