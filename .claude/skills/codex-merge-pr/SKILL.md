---
name: codex-merge-pr
description: >-
  Squash merge a pull request. The commit message comes from this workflow rather than from GitHub, whose own version concatenates every commit on the branch into text no linter ever reads. A briefing script prints the published description, every commit the squash collapses, and the diffstat, then leaves a SQUASH_AGENTMSG skeleton whose body the caller writes. Review, the commit-msg gates, and an operator confirmation all run before the merge. Use this whenever the user asks to merge or land a pull request, including one nobody here authored such as a dependency bump.
---

# Merge a pull request

Work the steps in order. Codex doesn't provide skill-scoped command hooks, so the scripts enforce the terminal invariants while these instructions keep every mutating command on the sanctioned path. Never run `gh pr merge` directly.

Left alone, GitHub writes the squash message by concatenating every commit on the branch. That text has never passed a commit-msg hook, and it arrives on the default branch where the rest of the toolchain assumes those hooks ran. Nothing lints it afterwards. This workflow writes the message itself and puts it through what a commit answers to.

## Preflight

Run `bash .agents/skills/codex-merge-pr/scripts/preflight.sh [number]`, passing the pull request number when the request names one.

## Step 0: open the task list

Create these with `update_plan`, keeping exactly one item `in_progress` at a time.

1. Confirm the pull request is mergeable
2. Settle the published description
3. Write the squash message in SQUASH_AGENTMSG
4. Review the message with codex-review-squash-message
5. Run the commit-msg gates
6. Confirm the message with the operator
7. Merge and clean up

Stop before any of it where preflight reports a missing precondition, a draft pull request, or a failing check. Say what's wrong and hand back.

## Step 1: confirm the pull request is mergeable

Preflight printed the state, the check rollup, and the review decision. Merging needs an open pull request that nobody marked as a draft, with every check green.

A failing check goes to `codex-fix-pr`, and a running one goes to `codex-watch-pr`. Neither belongs here, and the merge script refuses both anyway.

A `mergeStateStatus` of `BEHIND` or `DIRTY` is the third case. The branch needs the base underneath it before anything merges, so run the `codex-rebase` skill and push the result. Don't reach for GitHub's own update button: it merges the base into the branch, which leaves a merge commit this workflow never wrote a message for.

Where the repository requires a review decision, respect it. `CHANGES_REQUESTED` means the merge waits, whatever the checks say.

## Step 2: settle the description first

The description is on GitHub at this point, and often nothing sits on disk. Fetch it back before revising it:

```text
bash .agents/skills/codex-merge-pr/scripts/populate-description.sh <number>
```

That rebuilds `PR_AGENTDESC.md` from what the pull request currently says, reassembling the frontmatter from the properties set on the pull request. It refuses to overwrite an existing draft without `--force`, because a `pr` workflow further up the stack may have one in flight.

Merging is the last moment the description can change, and the squash message gets written from it, so a wrong description propagates that error into history.

Read what preflight printed under `== description as published ==` against the commits it collapses. Where it no longer describes the branch, delegate `codex-write-pr-description` and then `codex-review-pr-description` in fresh agents, following the `codex-pr` review loop, then republish with `bash .agents/skills/codex-pr/scripts/create-pr.sh`.

Most merges skip this. A description that still fits doesn't need a pass, and a pull request nobody here authored has none of this machinery behind it, so take its description as it stands.

## Step 3: write the squash message

```text
bash .agents/skills/codex-merge-pr/scripts/squash-message.sh <number>
```

That prints a briefing and writes a skeleton. Nothing in it converts the description into a message, because no rewriting rule produces one. The commit that merges here is the one a whole branch leaves behind, so writing it means reading everything that landed and deciding what a reader years from now still needs.

Your briefing carries the description as published, every commit message the squash collapses in full, the diffstat, and the trailers those commits carry. Read it before writing a word. Commit bodies matter most. Each one already argued for itself once, and this is the last place that argument survives. Run the command on its own and read the whole thing. Piping it through `head` or `tail` keeps the trailing skeleton and drops those bodies, which nothing else in this workflow prints, and the script caps nothing on purpose, so a cap you add is one nobody downstream can see you added.

`SQUASH_AGENTMSG` at the repository root holds the skeleton, which a gitignore entry keeps out of history. Subject and footer come filled in. The body stays empty until you write it.

### Subject

The script sets `<pull request title> (#<number>)`. Keep the reference, because `squash-merge.sh` reads it back to confirm the draft belongs to this pull request. Fix the rest where the title described one commit rather than the branch. A squash leaves one commit behind, so the subject names what the whole stack did.

### Body

The description was Markdown, written for a reviewer with the diff open beside it. This is plain text, and whoever reads it three years from now has neither.

Take from the description:

- Summary and Why, which carry the reason the branch exists
- Risk, but only where it names a rollback the reader wouldn't guess

Leave behind:

- Verification, entirely. It reported what a reviewer needed at the time, and the moment the suite changes it describes a run nobody can repeat.
- Risk that only says the change could be wrong.

Then read the result back against the commits. The commits outrank it. Descriptions get published early while branches keep growing, so the commits record what landed rather than what someone expected to land. Where a commit body gives a reason the description never stated, that reason belongs in the message. Otherwise it goes at the merge, with the commit that held it.

Avoid:

- Restating the diff. A reader who wants the what reads the diff.
- Walking the stack. A branch of eight commits becomes one account rather than eight paragraphs.
- Counting. No file, line, test, or commit counts.
- Provenance filler. Nothing about requests, review rounds, sessions, prompts, models, or tools.
- Markdown. No fenced blocks, headings, emphasis, links, or tables. Backticks around a literal identifier are fine.

Hard wrap the body at 72 characters and the trailers at 100.

### Footer

The script fills this in. `Closes` lines come from the description's Related section, and the trailers come from the commits themselves, ordered with attribution first and sign-off last.

Check the closing references before going on. Related lists whatever the author put there, so a number that names a pull request or a document rather than an issue this branch closes comes out of the footer.

## Step 4: review the message

Spawn a delegated agent with `fork_turns: "none"`. Tell it to use `codex-review-squash-message`, pass the absolute repository root, forbid edits, and require its exact verdict block as the final response. Wait for it to finish. This fresh thread hasn't watched you work and reads the message against every commit the squash collapses.

This step is mandatory, and the merge script enforces it. Save the delegated agent's exact final response in a temporary file, then run `bash .agents/skills/codex-merge-pr/scripts/stamp-review.sh <absolute-repository-root> <verdict-file>`. The script accepts only a clean verdict that names the exact PR head the reviewer read. It confirms that head is still current before signing it together with the exact draft bytes. A finding erases any earlier signature. Editing the draft or pushing another commit afterward voids it.

Fix everything it returns. Push back only where it's demonstrably wrong about the commits, and say why.

A finding names one instance rather than the fault itself. Fix the instance, then read the rest of the message for the same fault, because a reviewer that found one instance finds the next one on the next round.

## Step 5: run the commit-msg gates

```text
mise run lint-squash-msg
```

The same four hooks a commit answers to:

- vale under the commit scope, which catches AI tells through `ai-tells-commits`
- cspell with the commit dictionary
- commitlint for the Conventional Commits shape
- commit-trailers for trailer order

Resolve every finding. Edited the draft to clear them? Then step 4 runs again, because the gate compares bytes rather than intentions.

## Step 6: confirm with the operator

Print this first, verbatim:

```text
Merging: #<number> <title>
Into:    <base branch>
Commits: <count> collapsing into one

<the entire SQUASH_AGENTMSG contents, verbatim>
```

Preflight answered this under `== pre-approval ==`. Where it reported `merge: GRANTED`, the operator answered this question for this Codex thread in advance, through `mise run preapprove merge`. Print the preceding block so the message still reaches them, name the grant this merge goes under, and move to step 7.

The grant answers one question, merge under this message. Ask anyway where any of these holds:

- the review returned a finding nobody acted on
- the checks aren't green
- this pull request isn't the one the session set out to merge, which covers a dependency bump nobody here authored unless the operator named it

Where preflight reported `merge: not granted`, Default mode has no structured question tool. End the turn after the preceding block and ask `Squash merge with this message?`, presenting these four options in order:

| Label | Description |
| --- | --- |
| `Merge it` | The subject line, verbatim |
| `Revise the message` | `Redraft the message, review it again, and come back.` |
| `Wait on the checks` | `Hand this to watch-pr first, and merge once it reports green.` |
| `Stop here` | `Leave the pull request, the draft, and the branch untouched.` |

Don't merge in the same turn that asks. Resume only after an explicit answer. Follow it exactly. Revising sends you back through the delegated review because the gate compares bytes.

## Step 7: merge and clean up

```text
bash .agents/skills/codex-merge-pr/scripts/squash-merge.sh <number>
```

That script re-runs every gate before it touches anything. It checks that the message names this pull request, that the signature matches the bytes on disk and the current PR head, that the linters pass, and that the pull request is open, approved where required, mergeable, ready, and green. The merge itself names the reviewed head, so a commit pushed while the final checks run isn't part of the squash. Then it removes `SQUASH_AGENTMSG` and `PR_AGENTDESC.md` along with their signatures and deletes a merged branch only when it belongs to this repository. A fork branch remains untouched.

No post-merge hook exists to hang that cleanup on, so the script that watched the merge succeed does it.

Report the merged commit. Where this worktree stands on the branch that merged, the script says so rather than deleting the branch out from under the session. The operator decides whether to switch or drop the worktree.

## Preconditions

- `gh` installed and authenticated
- a `mise run lint-squash-msg` task
- a gitignore entry for `SQUASH_AGENTMSG`
- the `codex-review-squash-message` skill deployed alongside this one

Preflight checks each. Where one is missing, tell the operator rather than improvising a substitute.
