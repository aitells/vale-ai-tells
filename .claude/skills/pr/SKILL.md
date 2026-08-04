---
name: pr
license: Apache-2.0
description: >-
  Open a pull request for the current branch. A forked writer drafts the title and the pull request properties and the template's sections into PR_AGENTDESC.md. An independent reviewer then reads that draft against the branch, and a mechanical validator checks it against the template. The operator confirms before anything publishes. Whatever follows routes to the watch-pr and fix-pr and merge-pr skills. Use this whenever the user asks to open or draft a pull request in a tbhb repo, and whenever a task ends in one.
hooks:
  PreToolUse:
    - matcher: Write|Edit
      hooks:
        - type: command
          command: "${CLAUDE_PROJECT_DIR}/.claude/skills/write-pr-description/scripts/guard-draft.sh"
    - matcher: Bash
      hooks:
        - type: command
          command: "${CLAUDE_PROJECT_DIR}/.claude/skills/pr/scripts/guard-gh.sh"
  PostToolUse:
    - matcher: Skill
      hooks:
        - type: command
          command: "${CLAUDE_PROJECT_DIR}/.claude/skills/pr/scripts/stamp-review.sh"
---

# Open a pull request

Work the steps in order. A pair of hooks runs alongside them and refuses the shortcuts. A direct `gh pr create` is out, so is a `gh pr edit` rewriting the title or body, and so is any publish whose description the reviewer hasn't seen in its current form.

This skill ends when the pull request is open. From there `watch-pr`, `fix-pr`, and `merge-pr` take over, and step 8 routes to whichever the operator asked for.

## Preflight

!`bash ${CLAUDE_SKILL_DIR}/scripts/preflight.sh`

## Step 0: open the task list

Create these with `TaskCreate`, then move each through `in_progress` and `completed`.

1. Confirm the branch is ready
2. Draft the description in PR_AGENTDESC.md
3. Clear the prose gates with fix-prose
4. Review the draft with review-pr-description
5. Run the validator and the prose gates
6. Ask the operator how far to take it
7. Publish the pull request
8. Route the rest

Stop before any of it where preflight reports a rebase, merge, or cherry-pick in progress, or a missing precondition. Say what's wrong and hand back.

## Step 1: confirm the branch is ready

Preflight answered each of these, so read rather than re-run:

- The branch has commits the base doesn't. Nothing to open otherwise.
- The branch isn't the default branch.
- Uncommitted changes stay out of the pull request. Where preflight listed some, say so and let the operator decide before going on.
- A pull request may already exist. Where one is open, publishing updates it rather than opening a second.
- The branch has a current base. Where preflight reports it behind the default branch, run the `rebase` skill before opening, so the reviewer reads the branch against the base it actually merges into.

Preflight also settled the draft on disk. It removed a stale `PR_AGENTDESC.md` where no open pull request stood behind it, then scaffolded a fresh one from the template. That scaffold has the frontmatter keys, a placeholder title, and every section the template declares, so nothing downstream reproduces the template's shape from memory. It fails the validator until something fills it, which is the point.

## Step 2: draft the description

Invoke the `write-pr-description` skill, passing the repository root from preflight as its argument.

It runs forked, which keeps the branch diff in its context rather than this one, and it clears the mechanical validator before returning. It comes back with `DRAFT: WRITTEN` plus what it changed, or with `DRAFT: BLOCKED` plus what stopped it. Where it reports a block, say what it found and hand back, because this workflow has nothing left to publish.

Don't write `PR_AGENTDESC.md` yourself. A guard hook refuses it, because editing the draft here means reading the diff here, which spends the whole point of forking the writer.

## Step 3: clear the prose gates

Invoke the `fix-prose` skill, passing the draft and the task that judges it:

```text
Skill(fix-prose, args: "PR_AGENTDESC.md mise run lint-pr-description")
```

It runs the lint rounds in a subagent, so the findings stay out of this session.

Run it before the review rather than after. The review in the next step signs the exact bytes it cleared, and a lint fix landing later voids that signature and buys another round.

## Step 4: review the draft, and loop

Invoke the `review-pr-description` skill, passing the repository root. It runs as an independent agent that watched neither the work nor the drafting, so it reads the description against the branch with no memory of what anyone meant to write.

Its verdict drives a loop:

- `VERDICT: PASS` ends the loop. Go on to step 5.
- `VERDICT: CHANGES REQUIRED` sends the findings back to `write-pr-description`, verbatim, in its arguments. Then review again.

Bound it at three rounds. Past that, stop, and report which findings keep coming back, because a fourth pass at the same objection rarely resolves it.

This step is mandatory, and `create-pr.sh` enforces it. A clean verdict signs the exact bytes of the draft, a finding erases any earlier signature, and a later edit voids it the same way.

## Step 5: run the validator and the prose gates

```text
mise run lint-pr-description
```

That task runs the mechanical checks, then vale and cspell over the draft. The validator settles the frontmatter shape, the title's form and bounds, section presence and order, empty sections, surviving comments, unclosed fences, dead links, and whether every backticked path exists. Each finding names a line and the fix.

Resolve every one through `fix-prose` rather than editing it yourself, because a direct edit here spends the context that skill exists to save. Edited the draft either way? Then step 4 runs again, because the gate compares bytes rather than intentions.

## Step 6: ask the operator how far to take it

Print the draft first so the operator reads it in your message text rather than in the truncated widget:

```text
Branch:  <branch> into <base>
Commits: <count>

<the entire PR_AGENTDESC.md contents, verbatim>
```

Preflight answered both of this step's questions under `== pre-approval ==`. Where it reported `pr: GRANTED`, the operator answered them for the whole session in advance, through `mise run preapprove`. Print the preceding block so the draft still reaches them, name the grant this publish goes under, and take both answers from the grant rather than from a question:

| Preflight line | How far to take it | How fixes land |
| --- | --- | --- |
| `pr: GRANTED`, `merge: GRANTED` | `Open, fix, and merge` | Separate commits |
| `pr: GRANTED`, `merge: not granted` | `Open, watch, and fix` | Separate commits |

Separate commits are the pre-approved shape because amending rewrites a commit the operator already cleared, and a grant covering that would reach past the question it answers. Amend only where the operator asks for it in the session.

Ask anyway where any of these holds:

- the review returned a finding nobody acted on
- a gate needed more than a mechanical fix
- the branch reaches past what the session set out to do

Where preflight reported `pr: not granted`, call `AskUserQuestion` with `question` set to `How far should I take this?`, `header` set to `Pull request`, `multiSelect` set to `false`, and these four options in order, from the most automated to the least:

| Label | Description |
| --- | --- |
| `Open, fix, and merge` | `Open it, watch the checks, fix what fails, and squash merge once it is green.` |
| `Open, watch, and fix` | `Open it, watch the checks, and fix what fails. Stop before merging.` |
| `Open and watch` | `Open it, watch the checks, and report the result without changing anything.` |
| `Open only` | `Open it and hand back.` |

Ask a second question in the same call, so the operator answers both at once. Set `question` to `How should fix commits land?`, `header` to `Fixes`, `multiSelect` to `false`, and give these two options:

| Label | Description |
| --- | --- |
| `Separate commits` | `Each fix lands as its own commit. History keeps the record of what broke.` |
| `Amend and force-push` | `Fixes fold into the commit that caused them, pushed with --force-with-lease.` |

Neither answer is the safe default in general. A separate commit suits a branch under review, where a reviewer needs to see what changed since they last looked. Amending suits a branch nobody has read yet, where a lint fix of its own is noise the squash message would have to account for.

Record both answers. Step 8 routes on the first and passes the second to `fix-pr` in its arguments, so neither gets asked again.

A fifth path stays available without an option of its own. Where the operator wants the description changed, redraft it, put it back through the review, and return here.

## Step 7: publish the pull request

```text
bash .claude/skills/pr/scripts/create-pr.sh
```

That script is the only thing here that publishes, and it gates itself first:

- runs the validator over the draft again
- compares the review signature against the bytes on disk
- resolves labels, the milestone, and every issue reference against the API, so an unknown one refuses cleanly rather than leaving a published pull request missing what it should carry

Only then does the branch go up and the pull request open. A second run updates the open pull request rather than opening another.

Never call `gh pr create` yourself. A guard hook refuses it, because every gate named here lives in that script.

Report the URL.

## Step 8: route the rest

Follow the answer from step 6.

`Open only` ends here. Say the pull request is open and hand back.

`Open and watch` invokes `watch-pr` with the number, then reports what it found. Stop there even when something failed.

`Open, watch, and fix` invokes `watch-pr`, then `fix-pr` on failure, then `watch-pr` again to confirm. Repeat until the checks pass, then stop before merging. Bound the loop. After three rounds on the same check, stop, then report what each attempt changed.

`Open, fix, and merge` does the same, then invokes `merge-pr` with the number once the checks pass. That skill drafts the squash message and puts it through its own review. It also asks the operator to confirm before merging, so the merge gets a confirmation of its own.

Where the description drifts as remediation commits arrive, redraft it, review it again, and re-run `create-pr.sh` to update the published copy.

## Preconditions

This skill assumes the shared tbhb toolchain:

- `gh` installed and authenticated
- a `mise run lint-pr-description` task
- a gitignore entry for `PR_AGENTDESC.md`
- a pull request template at `.github/pull_request_template.md`
- the `review-pr-description` and `fix-prose` skills deployed alongside this one
- the `watch-pr`, `fix-pr`, and `merge-pr` skills deployed for step 8

Preflight checks each. Where one is missing, tell the operator rather than improvising a substitute.
