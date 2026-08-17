---
name: codex-commit
description: >-
  Group changes into atomic commits, draft and lint COMMIT_AGENTMSG, get an independent Codex review, explicitly confirm with the operator, commit through the protected wrapper, and rebase. Use whenever a tbhb repository task ends in a commit or the user asks to commit.
---

# Commit workflow

Run from the repository that holds the changes. Start with `.agents/skills/codex-commit/scripts/preflight.sh`.

Stop on an interrupted Git operation or missing precondition. Create and maintain an `update_plan` checklist for base, grouping, staging, draft, prose, review, gates, confirmation, commit, and rebase.

Use the recommended base from preflight. Read the whole diff and divide it into independently revertible logical changes. Stage every path by name with `git add --`. Never use `git add .`, `git add -A`, or `git add --all`. Confirm the index with the cached stat and short status.

Write the complete message to repo-root `COMMIT_AGENTMSG`. Use `<type>(<scope>)?(!)?: <imperative description>`. The body records why the change exists rather than restating the diff. Use only checked claims. Omit counts, sales language, and provenance. Hard-wrap body lines at 72 and trailers at 100. Put `Assisted-by` before the required `Signed-off-by` printed by preflight.

Invoke `codex-fix-prose` on `COMMIT_AGENTMSG mise run lint-commit-msg`. Then delegate `codex-review-commit-message` with `fork_turns: "none"`, supplying only the repository root, optional `--amend`, and instruction to follow that skill. Resolve every finding and repeat prose lint plus independent review until it returns exactly `VERDICT: PASS`.

Only after receiving that verdict, run:

```text
bash .agents/skills/codex-commit/scripts/stamp-review.sh <repo-root> <verdict-file>
mise run lint-commit-msg
```

Save the delegated agent's exact final response in the verdict file. The stamping script accepts only `VERDICT: PASS` and records both the draft digest and the staged tree.

After any edit to the draft or index, repeat the prose pass and independent review before stamping again.

## Confirmation and commit

Default mode always requires explicit operator confirmation unless preflight reports `commit: GRANTED`. Show the staged paths and complete message first. When the workflow needs confirmation, end the turn and ask `Commit this message?` Present `Commit it`, `Revise the message`, `Restage and redraft`, and `Stop here`. Don't commit in the turn that asks. The original request to commit doesn't count as this final confirmation.

After confirmation, commit only through:

```text
bash .agents/skills/codex-commit/scripts/commit.sh
```

The wrapper verifies the review digest and staged manifest. It accepts only `--amend`. Never invoke `git commit` directly or bypass hooks.

Rebase onto the recorded base with `rebase.updateRefs=false`, `rebase.autoSquash=false`, and `--autostash`. Never use a bare `git stash pop`. A conflict routes to `codex-rebase`. Report the resulting commit and any remaining atomic groups.

`CODEX_THREAD_ID` keys pre-approval. Without it, ask for confirmation. Ask despite a grant if review findings remain, a gate required judgment, grouping changed, or the commit exceeds the task’s scope.
