---
name: rebase
license: Apache-2.0
description: >-
  Replay the current branch onto its base and establish that the result is sound. Preflight settles the base by comparing the local default branch against origin's copy. The rebase runs under pinned settings. A range-diff afterwards says what the replay did to each commit. The gates then run against a tree no commit ever saw. Conflicts route to the resolve-rebase-conflicts skill. Use this whenever the user asks to rebase or to bring a branch current, and whenever a workflow needs the branch moved first.
hooks:
  PreToolUse:
    - matcher: Bash
      hooks:
        - type: command
          command: "${CLAUDE_PROJECT_DIR}/.claude/skills/rebase/scripts/guard-rebase.sh"
---

# Rebase workflow

Move the branch onto its base, then establish that what came out is right.

A guard hook runs alongside. It refuses a rebase started by hand and a continue past a conflict git never checked. It also refuses a dropped commit that isn't empty, a bare stash pop, and a force push without a lease.

## Preflight

!`bash ${CLAUDE_SKILL_DIR}/scripts/preflight.sh`

## Step 0: open the task list

Create these with `TaskCreate`, then move each through `in_progress` and `completed`.

1. Choose the base
2. Settle the working tree
3. Start the rebase
4. Resolve whatever it stops on
5. Verify the result
6. Report

Preflight reporting a merge or cherry-pick in progress stops everything. Say what's in the way and hand back. A rebase already in progress is the other case, and that one resumes at step 4.

## Step 1: choose the base

Preflight computed this under `== rebase base ==`. Take its recommendation.

- Local default branch carries everything the remote has, so rebase onto the local branch.
- Local default branch sits behind the remote, so rebase onto `origin/<default>` and skip the stale local copy.

The `commit` skill's preflight makes the same decision, and both reach the same answer. Where the operator names a different base, use theirs and say why it differs.

Nothing to replay means nothing to do. Say so and stop.

## Step 2: settle the working tree

`--autostash` handles a dirty tree, and `start-rebase.sh` passes it. It scopes the save to this rebase and never touches the shared stash stack, which is what makes it the sanctioned form here.

The stashed work sits outside the worktree while you resolve a conflict, so nothing you see there reflects it. It can also conflict on the way back once the replay finishes.

Where the work needs to survive a cancelled rebase as well, park it in a throwaway commit first:

```text
git commit -am wip --no-verify
```

That's the one sanctioned `--no-verify` in this repository, and `git reset --soft HEAD~1` afterwards removes it before anything reaches history.

Never a bare `git stash pop` or `git stash apply`. Worktrees share one global stash stack whose indices shift whenever any worktree pushes, so a bare pop takes whatever sits at `stash@{0}` right then. The guard hook refuses it.

## Step 3: start the rebase

```text
bash .claude/skills/rebase/scripts/start-rebase.sh <base>
```

Don't type the `git rebase` yourself. The script pins off `rebase.updateRefs`, an operator preference that quietly moves other local branches pointing into the replayed range. It pins off `rebase.autoSquash` as well, which would otherwise collapse a `fixup!` commit that earned its own review. Recording the pre-rebase tip is the third thing it does. Without that record, step 5 has nothing to compare against.

Exit `0` means the replay finished, so go to step 5. A `1` means it stopped, so go to step 4.

Read the output for a line about rerere replaying a recorded resolution. That's git staging a resolution from an earlier rebase without stopping, and nothing has read it since. Treat every such path as unverified.

## Step 4: resolve what it stops on

```text
bash .claude/skills/rebase/scripts/rebase-status.sh
```

That says which commit stopped, how far through the replay it sits, which paths remain unmerged, and what git staged without asking.

Then invoke the `resolve-rebase-conflicts` skill. It classifies each path before anything edits it and settles the mechanical ones itself, which covers most of them in this repository. Don't resolve conflicts here. The classification is what keeps a mechanical case from turning into a judgement call.

Once you have staged every path:

```text
bash .claude/skills/rebase/scripts/continue-rebase.sh
```

That reads the staged blobs for conflict markers before it advances. git checks only that no path remains unmerged, so a file you staged with `<<<<<<<` still in it continues straight into a commit.

Repeat from `rebase-status.sh` at each further stop. Where git calls a commit empty because the base already carries the change, `continue-rebase.sh --skip-empty` drops it after proving the index matches `HEAD`.

Giving up stays available, and it costs nothing:

```text
git rebase --abort
```

Reach for it when the conflicts say somebody cut this branch from the wrong place. Resolving thirty of them to reach that conclusion helps nobody.

## Step 5: verify the result

```text
bash .claude/skills/rebase/scripts/verify-rebase.sh
```

A rebase that ends without complaint has proved one thing: every commit applied. It has proved nothing else, and what it leaves unproved is where the trouble sits.

**A resolution can lose a hunk.** The commit still applies. Its message still describes the change it no longer makes, and no gate anywhere notices, because a commit that does less than it claims isn't a syntax error. The `range-diff` this script prints is what surfaces it. That view pairs each old commit against its replayed self, marking `=` where the commit came through unchanged and `!` where its content moved. Expect a `!` wherever you resolved a conflict. Treat one anywhere else as a question to answer before moving on.

**A tree can break with no commit at fault.** The base adds a gate, the branch adds a file that gate rejects, and neither side fails on its own. That combination first exists after the rebase.

Run the gate the script names:

```text
mise run check
```

Or `mise run lint` where the repository has no `check`. Either way, run it against the tree as it now stands rather than against any one commit, because the tree is the thing nothing has tested yet.

A failure here is an ordinary fix rather than a rebase problem. Correct it, and commit through the `commit` skill. Where the fix belongs inside a commit the rebase just replayed, say so and let the operator choose between a follow-up commit and an amend.

Where the branch runs long enough for a mid-history break to matter, the thorough form runs the gate at every commit:

```text
git -c rebase.updateRefs=false rebase --exec 'mise run lint' <base>
```

The script also names any path the repository declares generated through `rebase-resolve=regenerate`. The resolution took one side of those whole, on the understanding that the generator would overwrite it. Run the generator now, and commit what it changes.

## Step 6: report

Say what the base was, how many commits replayed, which paths conflicted, and how you settled each one. Give what the gates reported, and name anything the `range-diff` flagged.

Then hand back. Pushing is the caller's call. A rebase rewrites the branch, so the push needs `git push --force-with-lease origin HEAD`. The guard refuses a bare `--force`, because the lease is what keeps the push from discarding whatever arrived while this session worked. Where a pull request is open, `pr` and `watch-pr` take it from there.

## Where this sits

The `commit` skill rebases onto the base itself as its last step, and for a clean replay that's the whole story. Come here when that rebase stops on a conflict, when the branch needs moving without a commit in hand, or when the result needs the verification step this skill runs.

## Preconditions

- a git repository with a resolvable default branch
- the `resolve-rebase-conflicts` skill deployed alongside this one
- a `mise run check` or `mise run lint` task for the verification to run

Preflight checks each and says which are missing.
