---
name: commit
license: Apache-2.0
description: >-
  Group changes into one atomic commit, draft a Conventional Commit message in COMMIT_AGENTMSG, put it through an independent review and the commit-msg gates, confirm it with the operator, then commit and rebase. Use this skill whenever the user asks to commit work in a tbhb repo ("commit this," "commit the staged changes," "write a commit message") or whenever a task ends in creating a commit.
hooks:
  PreToolUse:
    - matcher: Bash
      hooks:
        - type: command
          command: "${CLAUDE_PROJECT_DIR}/.claude/skills/commit/scripts/guard-git.sh"
  PostToolUse:
    - matcher: Skill
      hooks:
        - type: command
          command: "${CLAUDE_PROJECT_DIR}/.claude/skills/commit/scripts/stamp-review.sh"
---

# Commit workflow

Work the steps in order. A guard hook runs alongside them and refuses whole-tree staging along with any `git commit` you write out yourself. Step 8 names the one script that commits, and that script refuses an inline `-m` message, a `--no-verify`, and a draft the reviewer hasn't seen in its current form.

Those hooks stay registered for the rest of the session so they carry a scope. Preflight arms the guard at the commit `HEAD` sits on now. Step 8 moves `HEAD` past that mark and stands the guard down. Work later in the session is none of the guard's business. A second commit means invoking this skill again rather than carrying on from here.

## Preflight

!`bash ${CLAUDE_SKILL_DIR}/scripts/preflight.sh`

## Step 0: open the task list

Create these tasks with `TaskCreate`, then move each to `in_progress` and `completed` as you go. They're the checklist the rest of this document expands.

1. Choose the rebase base
2. Group the changes into atomic commits
3. Stage the paths for this commit
4. Draft the message in COMMIT_AGENTMSG
5. Clear the prose gates with fix-prose
6. Review the draft with review-commit-message
7. Run the commit-msg gates
8. Confirm the message with the operator
9. Commit and rebase

Stop before any of it if preflight reports a rebase, merge, or cherry-pick in progress, or a missing precondition. Say what's wrong and hand back.

## Step 1: choose the rebase base

Preflight computed this under `== rebase base ==`. Take its recommendation:

- Local default branch carries everything the remote has, so rebase onto the local branch.
- Local default branch sits behind the remote, so rebase onto `origin/<default>` and skip the stale local copy.

Record the base now. Step 9 rebases onto it without asking again. Worktrees under `.claude/worktrees` are the usual layout here, and each one carries its own checkout of the branch.

## Step 2: group the changes into atomic commits

Read the diff before deciding anything. One commit carries one logical change: the reader can state its purpose in a sentence, and reverting it undoes that purpose and nothing else.

Split when the outstanding work covers more than one of these:

- A behavior change and an unrelated refactor
- A fix and the formatting sweep that came with it
- A pair of features that don't depend on each other
- Production code and unrelated tooling or configuration

A dependency doesn't force a split. Code and the test that covers it belong together, as do a change and the documentation that describes it.

When the work splits, commit the first group through this workflow, then say which groups remain and run the workflow again for each. Never bundle them because bundling is quicker.

When one file mixes two logical changes, stage the relevant hunks with `git add -p`, or say so and let the operator decide.

## Step 3: stage the paths for this commit

Name every path:

```text
git add -- path/one path/two
```

Never `git add -A`, `git add .`, or `git add --all`. They sweep in whatever else is uncommitted, which is how an atomic commit stops being atomic. The guard hook refuses all three.

Confirm the result with `git diff --cached --stat` and `git status --short`. The staged set matches the group from step 2, and anything left unstaged belongs to a later commit.

## Step 4: draft the message in COMMIT_AGENTMSG

Write the whole message to `COMMIT_AGENTMSG` at the repo root. A gitignore entry keeps it out of history, and a post-commit hook deletes it after the commit succeeds.

### Subject

`<type>(<scope>)?(!)?: <description>`, with the type drawn from the list preflight printed. Imperative mood, present tense, lowercase after the colon, no trailing period, and the whole line inside the bounds preflight reported. Write the description as the instruction the commit carries out: `explain the tools`, not `explains` and not `explained`.

### Body

The body answers why this change exists. The diff already says what changed, and a reader who wants the what reads the diff.

Write:

- The problem, the constraint, or the tradeoff that made this the answer
- Why this approach rather than the obvious alternative
- What breaks without it, or where the need came from
- A decision worth recording, so nobody relitigates it later

Avoid:

- Restating the diff. `Adds a helper to foo.go and calls it from bar.go` is the diff, spelled out longer.
- Counting. No file, line, test, function, or commit counts. A count goes stale as soon as other work merges, and it reads as padding.
- Provenance filler. Nothing about requests, review rounds, sessions, prompts, models, or tools. The `Assisted-by` trailer carries attribution.
- Claims you haven't checked. Leave out benchmark numbers you didn't measure and a `fixes the flake` for a flake you never reproduced.
- Selling it. Drop `robust`, `comprehensive`, `significantly`, `seamlessly`, and their neighbors.
- Markdown. No fenced blocks, headings, emphasis, links, or tables. Backticks around a literal identifier are fine.

Hard wrap the body at the width preflight reported. Wrap trailers at the footer width.

### Trailers

`Assisted-by` before `Signed-off-by`, matching the format and the sign-off identity preflight printed. Never credit a model through `Co-authored-by`.

## Step 5: clear the prose gates

Invoke the `fix-prose` skill before the review, passing the draft and the recipe that judges it:

```text
Skill(fix-prose, args: "COMMIT_AGENTMSG just lint-commit-msg")
```

It runs the lint rounds in a subagent, so the findings and the retries stay out of this session. The commit scope is stricter than the repository-wide one, and a message copied verbatim out of the diff still fails it, so this is rarely a no-op.

Order matters here. The review in the next step signs the exact bytes it cleared, and a lint fix landing afterwards voids that signature and costs another review round over a comma. Clearing the gates first is what keeps the loop to one pass.

Where it returns `PROSE: PARTIAL`, a finding needs a decision rather than another round. Read the short list, settle it, and send the answer back in the arguments.

## Step 6: review the draft

Invoke the `review-commit-message` skill, passing the repo root from preflight as its argument. It runs as an independent agent that hasn't watched you work, which is the point: it reads the draft against the staged diff with no memory of what you meant to write.

This step is mandatory, and the script in step 8 enforces it. A clean verdict signs the exact bytes of the draft, and a finding erases any earlier signature, so the commit stays blocked until a review clears the text as it stands. Editing the draft afterward voids the signature the same way.

Fix everything it returns. Push back only when it's demonstrably wrong about the diff, and say why.

## Step 7: run the commit-msg gates

```text
just lint-commit-msg
```

That recipe mirrors the commit-msg hook:

- vale under the commit scope, which catches AI tells through `ai-tells-commits`
- cspell with the commit dictionary
- commitlint for the Conventional Commits shape
- commit-trailers for trailer order

Step 5 should have left this clean. Where it hasn't, send the findings back to `fix-prose` rather than editing the draft here, because a hand-edit spends the context that skill exists to save.

Edited the draft to clear the linters? Then step 6 runs again before you commit, because the gate compares bytes rather than intentions.

Whatever this recipe reports, `.git/COMMIT_EDITMSG` and its commit-msg hook stay the real gate. A clean run here only predicts that hook's verdict.

## Step 8: confirm with the operator

`AskUserQuestion` truncates its options, so the operator reads the message in your message text rather than in the widget. Print this first, verbatim:

```text
Staged: <paths, comma separated>

<the entire COMMIT_AGENTMSG contents, verbatim>
```

Now call `AskUserQuestion` with `question` set to `Commit this message?`, `header` set to `Commit`, `multiSelect` set to `false`, and these four options in order:

| Label | Description |
| --- | --- |
| `Commit it` | The subject line, verbatim |
| `Revise the message` | `Staging stands. Redraft the message, review it again, and come back.` |
| `Restage and redraft` | `The grouping is wrong. Regroup the changes and start from step 2.` |
| `Stop here` | `Leave the draft, the index, and the branch untouched.` |

Follow the answer. Revising or restaging sends you back through the review, because the gate compares bytes.

## Step 9: commit and rebase

```text
bash .claude/skills/commit/scripts/commit.sh
```

Nothing else commits. The guard hook refuses a `git commit` you write out yourself whatever flags it carries, because every gate named below lives in the script and a hook on the tool call can't reach inside one.

That script checks the review signature and records what the staging area holds before it commits, then reads the commit back and compares. prek stashes and restores the worktree around the pre-commit hooks. A failed run can leave a path unstaged that you staged before the attempt, and the retry then commits part of the group without reporting it. The script prints every path it expected and didn't find and then fails. Its output is the check, so nothing needs a `git show --stat` after it.

The script pins `commit.cleanup=whitespace` for you. At the default of `strip`, git drops every body line opening with a number sign, and it does so after `review-commit-message` has hashed the file, so the bytes the reviewer cleared stop matching the bytes git records.

Only `--amend` passes through, which is the form `fix-pr` routes here for. The script refuses every other flag, because a hook reading the tool call sees `bash commit.sh` and none of the flags underneath it.

Then rebase onto the base from step 1, without asking:

```text
git -c rebase.updateRefs=false -c rebase.autoSquash=false rebase --autostash <base>
```

Same reasoning, two more knobs. `rebase.updateRefs` quietly moves other local branches that point into the replayed range. `rebase.autoSquash` collapses any `fixup!` commit, each of which earned its own review.

`--autostash` scopes the save to the rebase itself. Never a bare `git stash pop`: worktrees share one stash stack, so a bare pop can take another session's entry.

Where that rebase stops on a conflict, hand it to the `rebase` skill rather than resolving it here. That skill owns the classification, the resolution, and the check on what the replay did to each commit.

Report the resulting commit, then the groups still waiting from step 2, if any.

## Preconditions

This skill assumes the shared tbhb toolchain:

- a `just lint-commit-msg` recipe
- a gitignore entry for `COMMIT_AGENTMSG`
- the prek hooks installed, including the post-commit stage
- the `review-commit-message` and `fix-prose` skills deployed alongside this one

Preflight checks each. When one is missing, tell the operator rather than improvising a substitute.

The workflow commits the repository holding the session. `review-commit-message` reads its draft and its diff from that root, and step 8's script reads the draft and the signature from whichever repository it runs in. A sibling checkout carries no signature of its own, so the script stops there rather than committing on a review that read another tree. To commit a different repository, open a session there.
