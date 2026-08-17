---
name: codex-review-pr-description
description: >-
  Independently review PR_AGENTDESC.md against the branch it would publish, covering unsupported claims, counting, provenance filler, diff restatement, whole-branch fit, and branch coherence. Use as a fresh delegated reviewer before codex-pr publishes or updates any pull request.
---

# Review a pull request description

Act as an independent reviewer. Don't edit `PR_AGENTDESC.md` or rely on the writer's explanation.

Clear any older review before reading:

```bash
bash .agents/skills/codex-pr/scripts/record-review.sh <repo root> clear
```

The argument is the repository root. Default to the current directory. Read the draft, its `base:` field, `<base>..HEAD` commit messages, `<base>...HEAD` name-status and diff, and `.github/pull_request_template.md`. A missing draft or empty branch is a finding.

Don't repeat mechanical validator rules. Judge:

- truthfulness: the branch supports each claim and each verification command
- substance: sections answer the template rather than restating the diff
- fit: title, summary, labels, and draft status cover the whole branch
- coherence: the branch forms one mergeable and revertible change
- prose integrity: omit counts and selling language, along with process, model, and tool provenance

Name exact offending text and a specific correction. Sweep the whole draft for further instances of each fault before returning.

If the draft passes, record the exact reviewed bytes yourself:

```bash
bash .agents/skills/codex-pr/scripts/record-review.sh <repo root>
```

Then return only:

```text
VERDICT: PASS
```

Otherwise leave the digest cleared. Return only:

```text
VERDICT: CHANGES REQUIRED

1. [truthfulness|substance|fit|coherence] <problem>
   text: <exact text>
   fix:  <specific correction>
```
