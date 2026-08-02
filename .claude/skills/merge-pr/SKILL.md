---
name: merge-pr
license: Apache-2.0
description: >-
  Squash merge a pull request under a commit message this workflow writes rather than one GitHub concatenates. Drafts that message in SQUASH_AGENTMSG from the published description, then puts it through an independent review plus the commit-msg gates and an operator confirmation before merging and cleaning up. Use this whenever the user asks to merge or land a pull request, including one nobody here authored such as a dependency bump.
hooks:
  PreToolUse:
    - matcher: Write|Edit
      hooks:
        - type: command
          command: "${CLAUDE_PROJECT_DIR}/.claude/skills/write-pr-description/scripts/guard-draft.sh"
    - matcher: Bash
      hooks:
        - type: command
          command: "${CLAUDE_PROJECT_DIR}/.claude/skills/merge-pr/scripts/guard-merge.sh"
  PostToolUse:
    - matcher: Skill
      hooks:
        - type: command
          command: "${CLAUDE_PROJECT_DIR}/.claude/skills/merge-pr/scripts/stamp-review.sh"
---

# Merge a pull request

Work the steps in order. A pair of hooks runs alongside them and refuses the shortcut: a direct `gh pr merge`, and any merge whose message the reviewer hasn't seen in its current form.

Left alone, GitHub writes the squash message by concatenating every commit on the branch. That text has never passed a commit-msg hook, and it arrives on the default branch where the rest of the toolchain assumes those hooks ran. Nothing lints it afterwards. This workflow writes the message itself and puts it through what a commit answers to.

## Preflight

!`bash ${CLAUDE_SKILL_DIR}/scripts/preflight.sh ${ARGUMENTS}`

## Step 0: open the task list

Create these with `TaskCreate`, then move each through `in_progress` and `completed`.

1. Confirm the pull request is mergeable
2. Settle the published description
3. Draft the squash message in SQUASH_AGENTMSG
4. Review the draft with review-squash-message
5. Run the commit-msg gates
6. Confirm the message with the operator
7. Merge and clean up

Stop before any of it where preflight reports a missing precondition, a draft pull request, or a failing check. Say what's wrong and hand back.

## Step 1: confirm the pull request is mergeable

Preflight printed the state, the check rollup, and the review decision. Merging needs an open pull request that nobody marked as a draft, with every check green.

A failing check goes to `fix-pr`, and a running one goes to `watch-pr`. Neither belongs here, and the merge script refuses both anyway.

Where the repository requires a review decision, respect it. `CHANGES_REQUESTED` means the merge waits, whatever the checks say.

## Step 2: settle the description first

The description lives on GitHub at this point, and often nothing sits on disk. Fetch it back before revising it:

```text
bash .claude/skills/merge-pr/scripts/populate-description.sh <number>
```

That rebuilds `PR_AGENTDESC.md` from what the pull request currently says, reassembling the frontmatter from the properties it carries. It refuses to overwrite an existing draft without `--force`, because a `pr` workflow further up the stack may have one in flight.

Merging is the last moment the description can change, and the squash message gets written from it, so a description carrying something wrong propagates that into history.

Read what preflight printed under `== description as published ==` against the commits it collapses. Where it no longer describes the branch, invoke `write-pr-description` with the repository root and a note on what drifted, then `review-pr-description`, then republish with `bash .claude/skills/pr/scripts/create-pr.sh`.

Most merges skip this. A description that still fits needs no pass, and a pull request nobody here authored has none of this machinery behind it, so take its description as it stands.

## Step 3: draft the squash message

```text
bash .claude/skills/merge-pr/scripts/squash-message.sh <number>
```

That writes `SQUASH_AGENTMSG` at the repository root from the published description. Summary, Why, and Risk become the body. Related becomes closing references, and the trailers come from the commits themselves. A gitignore entry keeps the file out of history.

What it writes is a starting draft. Rewrite it before going on.

### Subject

The script sets `<pull request title> (#<number>)`. Keep the reference, and fix the rest where the title described one commit rather than the branch. A squash leaves one commit behind, so the subject names what the whole branch did.

### Body

The description was Markdown for a reviewer. This is plain text for whoever runs `git log` in three years, and the two read differently.

Write:

- The problem, the constraint, or the tradeoff that made this the answer
- Why this approach rather than the obvious alternative
- What breaks without it, or where the need came from

Avoid:

- Restating the diff. A reader who wants the what reads the diff.
- Counting. No file, line, test, or commit counts.
- Provenance filler. Nothing about requests, review rounds, sessions, prompts, models, or tools.
- Anything addressed to a reviewer. Verification notes belonged to the pull request.
- Markdown. No fenced blocks, headings, emphasis, links, or tables. Backticks around a literal identifier are fine.

Hard wrap the body at 72 characters and the trailers at 100.

## Step 4: review the draft

Invoke the `review-squash-message` skill, passing the repository root as its argument. It runs as an independent agent that hasn't watched you work, so it reads the message against the diff with no memory of what you meant to write.

This step is mandatory, and the merge script enforces it. A clean verdict signs the exact bytes of the draft, a finding erases any earlier signature, and editing the draft afterward voids it the same way.

Fix everything it returns. Push back only where it's demonstrably wrong about the diff, and say why.

## Step 5: run the commit-msg gates

```text
just lint-squash-msg
```

The same four hooks a commit answers to:

- vale under the commit scope, which catches AI tells through `ai-tells-commits`
- cspell with the commit dictionary
- commitlint for the Conventional Commits shape
- commit-trailers for trailer order

Resolve every finding. Edited the draft to clear them? Then step 4 runs again, because the gate compares bytes rather than intentions.

## Step 6: confirm with the operator

`AskUserQuestion` truncates its options, so the operator reads the message in your message text rather than in the widget. Print this first, verbatim:

```text
Merging: #<number> <title>
Into:    <base branch>
Commits: <count> collapsing into one

<the entire SQUASH_AGENTMSG contents, verbatim>
```

Now call `AskUserQuestion` with `question` set to `Squash merge with this message?`, `header` set to `Merge`, `multiSelect` set to `false`, and these four options in order:

| Label | Description |
| --- | --- |
| `Merge it` | The subject line, verbatim |
| `Revise the message` | `Redraft the message, review it again, and come back.` |
| `Wait on the checks` | `Hand this to watch-pr first, and merge once it reports green.` |
| `Stop here` | `Leave the pull request, the draft, and the branch untouched.` |

Follow the answer. Revising sends you back through the review, because the gate compares bytes.

## Step 7: merge and clean up

```text
bash .claude/skills/merge-pr/scripts/squash-merge.sh <number>
```

That script re-runs every gate before it touches anything. It checks that the message names this pull request, that the signature matches the bytes on disk, that the linters pass, and that the pull request is open, ready, and green. Then it merges, removes `SQUASH_AGENTMSG` and `PR_AGENTDESC.md` along with their signatures, and deletes the merged branch.

No post-merge hook exists to hang that cleanup on, so the script that watched the merge succeed does it.

Report the merged commit. Where this worktree stands on the branch that merged, the script says so rather than deleting the branch out from under the session. The operator decides whether to switch or drop the worktree.

## Preconditions

- `gh` installed and authenticated
- a `just lint-squash-msg` recipe
- a gitignore entry for `SQUASH_AGENTMSG`
- the `review-squash-message` skill deployed alongside this one

Preflight checks each. Where one is missing, tell the operator rather than improvising a substitute.
