---
name: commit
license: Apache-2.0
description: >-
  Draft, lint, and create a commit with a validated Conventional
  Commit message. The workflow drafts the message in a repo-root
  COMMIT_AGENTMSG file, validates it with `just lint-commit-msg`,
  and commits the validated draft with `git commit -F
  COMMIT_AGENTMSG`. Use this skill whenever the user asks to commit
  work in a tbhb repo ("commit this", "commit the staged
  changes", "write a commit message") or whenever a task ends in
  creating a commit.
---

# Commit message workflow

Draft every commit message in a repo-root file named `COMMIT_AGENTMSG`
before you run `git commit`. A gitignore entry keeps that file out of
history, so it serves purely as a scratchpad for iterating on the
message.

1. Write the full message (subject, body, and trailers) to
   `COMMIT_AGENTMSG`.
2. Run `just lint-commit-msg` and resolve whatever it reports.
3. Commit the validated draft with `git commit -F COMMIT_AGENTMSG`.

`just lint-commit-msg` mirrors the commit-msg hook: vale under the
commit scope (which catches AI commit tells via `ai-tells-commits`),
cspell with the commit dictionary, commitlint for the Conventional
Commits shape, and commit-trailers for trailer order. Running it while
drafting surfaces problems early, rather than at the commit-msg hook
where a late failure interrupts the commit.

The commit-msg hook on `.git/COMMIT_EDITMSG` stays the real gate.
`COMMIT_AGENTMSG` and its lint recipe only preview that gate, so a
clean recipe run predicts a clean commit but never replaces the hook.

## Preconditions

This skill assumes the shared tbhb repo toolchain: a
`just lint-commit-msg` recipe and a gitignore entry for
`COMMIT_AGENTMSG`. If the repo lacks either, tell the user instead of
improvising a substitute workflow.
