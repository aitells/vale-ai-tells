---
name: codex-review-commit-message
description: >-
  Independently review COMMIT_AGENTMSG against the staged diff for unsupported claims, diff restatement, provenance filler, form, and atomicity. The codex-commit skill delegates this review before every commit. Use only as a read-only reviewer.
---

# Review a commit message

The caller supplies a repository root and optionally `--amend`. Work read-only. Don't trust the caller's summary. Never write a review stamp.

Gather `COMMIT_AGENTMSG`, the staged name-status and patch, and five recent subjects. For `--amend`, compare against `HEAD~1` so the review covers the complete amended commit rather than only the new staged delta. A missing draft or empty applicable diff is a finding.

Check:

- The diff must support every claim. Reject counts, unverified results, selling language, and provenance about requests, sessions, prompts, models, or tools.
- The body explains why the change exists instead of spelling out the diff or repeating the subject.
- The subject is Conventional Commits form, imperative, present tense, 10 to 80 characters, and has no trailing period.
- Body lines are at most 72 characters, footer lines at most 100, and the message is plain text. `Assisted-by` precedes `Signed-off-by`. No assistant appears as `Co-authored-by`.
- The staged change is one logical, independently revertible change. Name separate groups when it isn't.

Return exactly one form:

```text
VERDICT: PASS
```

or:

```text
VERDICT: CHANGES REQUIRED

1. `<exact text or staged group>` — <problem>. Fix: <specific correction>.
```

Report every instance in one pass. Don't edit files, stage paths, or run mutating Git commands.
