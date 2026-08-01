---
paths:
  - "**"
---

# Worktree work-in-progress and stash rules

Repos following these rules run more than one agent worktree session
at a time, and every worktree shares one global `git stash` stack. An
unqualified stash pop in one worktree can grab another worktree's
entry. These rules keep cross-step persistence safe under that
constraint.

## Stash

- Reach for `git rebase --autostash` instead of a manual stash when
  you rebase a dirty worktree. It scopes the save to the rebase and
  never touches the shared stack.
- Never run a bare `git stash pop` or `git stash apply`. The shared
  stack shifts indices whenever any worktree pushes, so a bare pop
  targets whatever sits at `stash@{0}` at that instant, which may
  belong to another session.
- When you can't avoid a manual stash, name it with
  `git stash push -m`, run `git stash list` right before restoring,
  match your own message, and pop the explicit `stash@{n}`.

## Work-in-progress commits

Prefer a throwaway work-in-progress commit over a stash for any state
that needs to survive a rebase or a branch switch. A commit lives on
the branch, so it stays clear of the shared stash stack entirely.

```bash
git commit -am wip --no-verify   # park work in progress
# ... rebase, switch, or other operation ...
git reset --soft HEAD~1          # unwind, restoring the staged changes
```

The `--no-verify` flag belongs here because the pre-commit hooks
reject an intentionally incomplete snapshot over formatting, lint,
copyright headers, and the rest. This throwaway commit marks the one
sanctioned exception to the project-wide no-`--no-verify` rule, and
`git reset --soft` removes it before anything reaches history. A real
commit that reaches the branch never carries `--no-verify`. It runs
through the full hook suite.
