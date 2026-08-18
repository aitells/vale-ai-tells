---
name: codex-pr
description: >-
  Open or update a pull request for the current branch with an independently drafted and reviewed PR_AGENTDESC.md. Use whenever the user asks Codex to open or draft a pull request in a tbhb repository, or when a completed task should end in a pull request. Routes later CI work to codex-watch-pr and codex-fix-pr.
---

# Open a pull request

Use `update_plan` for these phases: preflight, draft, prose gates, independent review, confirmation, publication, and requested follow-through. Keep only one phase `in_progress`.

## Preflight

Run:

```bash
bash .agents/skills/codex-pr/scripts/preflight.sh
```

Stop on a missing prerequisite or an interrupted Git operation. If the branch is behind its base, use `codex-rebase` first. Tell the user about uncommitted changes before continuing. The preflight scaffolds `PR_AGENTDESC.md` and reports an existing pull request.

## Draft with a delegated writer

Spawn one subagent with this bounded task:

```text
Use the codex-write-pr-description skill in <repo root>. Write or revise PR_AGENTDESC.md, run its validator, and return only its DRAFT result.
```

Don't draft the file in the calling context. If the writer reports `DRAFT: BLOCKED`, report the blocker and stop.

Run the prose workflow over `PR_AGENTDESC.md` with `mise run lint-pr-description` when `codex-fix-prose` is available. Otherwise run that task directly and resolve only mechanical findings.

## Review with a fresh delegated agent

Spawn a different subagent:

```text
Use the codex-review-pr-description skill in <repo root>. Review PR_AGENTDESC.md against the branch and return its verdict.
```

On `CHANGES REQUIRED`, send the findings verbatim to a fresh writer, then review again with a fresh reviewer. Bound finding-driven revisions at three. After `PASS`, the reviewer records the reviewed digest through `record-review.sh`. Don't run that script from the calling agent.

Run `mise run lint-pr-description` after review. Any edit invalidates the digest, so repeat the independent review after a change.

## Get confirmation in default mode

Show the branch, base, commit count, and complete draft. Unless preflight reports `pr: GRANTED`, ask before publication by putting this question and its choices in the final response when using Default mode:

- open, fix, and merge
- open, watch, and fix
- open and watch
- open only

Also ask whether fixes should be separate commits or amendments. A pre-approval chooses separate commits and routes through merge only when `merge: GRANTED`. Stop there: don't publish in the turn that asks for confirmation.

## Publish

After confirmation, run only:

```bash
bash .agents/skills/codex-pr/scripts/create-pr.sh
```

The script checks the draft and requires the recorded digest to match its current bytes. It also resolves properties, pushes, and creates or updates the pull request. Don't bypass it with a direct mutating `gh pr` call. Report the URL.

Route follow-through to `codex-watch-pr` and `codex-fix-pr` according to the confirmed choice. Bound repeated fixes of the same check at three. Use `codex-merge-pr` only when the user explicitly requested merging or pre-approved it.

## Preconditions

- authenticated `gh`
- `mise run lint-pr-description`
- ignored `PR_AGENTDESC.md`
- `.github/pull_request_template.md`
- the sibling Codex skills named in the preceding sections
