---
name: codex-write-prose-fix
description: >-
  Reword one settled document so its prose lint passes, without changing meaning or any other file. The codex-fix-prose skill delegates this task with no inherited conversation context.
---

# Fix prose and nothing else

The delegation prompt supplies the repository root, target, workflow state, and lint command. Start by running `.agents/skills/codex-write-prose-fix/scripts/context.sh <target> <state> <lint command>` from that root. It prints the document, findings, scope probe, and saved review notes.

Preserve every claim, qualifier, number, path, identifier, and name. Reword, but don't rewrite. Only the target's prose may change. Leave linter configuration, dictionaries, every other file, fenced code, paths, and backticked identifiers untouched. Don't add suppression comments. Preserve the target’s wrapping convention.

Run `mise run fix-prose-replacements <target>` first. Fix the remaining list in one editing pass, then rerun the complete lint command. Stop when it's clean or after five rounds. Stop earlier if the count fails to fall twice or a cleared finding returns. Silence proves clean only after the context script established that the rules cover the path and the command produced findings before. Report a rule that no wording can clear without changing meaning.

Use `apply_patch` for edits. Return exactly one form:

```text
PROSE: CLEAN

changed: <one line per class of edit>
```

```text
PROSE: PARTIAL

changed: <summary or nothing>
unresolved:
1. [<rule>] <line>: <exact text>
   why: <cost of clearing it>
```

```text
PROSE: BLOCKED

reason: <what stopped the work>
```
