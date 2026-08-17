---
name: codex-write-pr-description
description: >-
  Write or revise PR_AGENTDESC.md from the branch, its commits, and the repository template, then run the mechanical validator until it reports nothing. Use as a delegated writer from codex-pr, codex-fix-pr, or codex-merge-pr. Pass review findings or branch-drift notes in the task.
---

# Write a pull request description

Work only in the repository named by the caller. The task may also carry review findings or a note about new commits. Resolve every supplied finding.

Gather context once:

```bash
bash .agents/skills/codex-write-pr-description/scripts/context.sh
```

Write `PR_AGENTDESC.md` with exactly these elements: YAML frontmatter containing `base`, `draft`, `labels`, `reviewers`, `assignees`, and `milestone`, followed by a Conventional Commits level-one title. Put every section the repository template declares after the title, in the template's order. Use a nonempty label list drawn from the context.

Describe the whole branch. Keep Summary, Why, Verification, Risk, and Related distinct. Verification names commands actually run. Avoid counts, diff narration, unsupported claims, selling language, and request/session/model/tool provenance. Preserve accurate existing prose during revisions.

Before returning, read the finished draft for closed enumerations and scope words such as `only`, `every`, and `never`. Establish those claims from the branch or weaken them.

Run until clean:

```bash
bash .agents/skills/codex-pr/scripts/validate-description.sh
```

Return only one of:

```text
DRAFT: WRITTEN

changed: <one line per material edit, or first draft>
addressed: <each supplied finding, or nothing requested>
```

```text
DRAFT: BLOCKED

reason: <decision or missing prerequisite>
```
