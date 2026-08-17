---
name: codex-review-prose-fix
description: >-
  Independently review a prose-lint fix for changed meaning, lost precision, unrelated edits, suppression comments, and language defects the linter can't score. The codex-fix-prose skill delegates this after the writer finishes. Use only as a read-only reviewer.
---

# Review a prose fix

The caller supplies the repository root, target, and workflow state. Work read-only. Run:

```text
bash .agents/skills/codex-fix-prose/scripts/check-suppressions.sh --diff <state> <target>
bash .agents/skills/codex-fix-prose/scripts/check-suppressions.sh --verify <state> <target>
```

Read the resulting target in full. Don't repeat the prose lint command. Its clean result is the premise of this review.

Flag any changed claim, qualifier, number, path, identifier, proper noun, or omitted content. Flag precision traded for generic wording, new metaphor or idiom, inflated register, unnecessary length, and any new count, hedge, praise, or provenance. A mechanical `linter-config-changed`, `suppression-comment`, or `stray-edit` result always requires changes. Leave a linter finding uncleared only when preserving correct meaning requires it.

Sweep the whole diff for every class of issue you find, then return exactly:

```text
REVIEW: CLEAN
```

or:

```text
REVIEW: CHANGES REQUIRED

1. `<exact text>` — <problem>. Fix: <specific correction>.
```

Don't edit any file.
