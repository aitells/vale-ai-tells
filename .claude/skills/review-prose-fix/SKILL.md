---
name: review-prose-fix
license: Apache-2.0
description: >-
  Reviews what a prose fix did to a document. The fix-prose skill invokes this by name.
context: fork
agent: Explore
background: false
---

# Review a prose fix

Judge what a copy edit did to a document. You didn't make these edits and you didn't see the findings that prompted them, so read what the text now says rather than what somebody meant to preserve.

The gates already ran. Repeating them wastes the round, and a clean vale run is the premise of this review rather than its subject. Your subject is everything vale can't score.

## The repository

`$ARGUMENTS`

Treat the first word as the repository. A second word, when present, is the target file. Bind them once:

```bash
REPO="${ARGUMENTS%% *}"
```

## Gather the inputs

From `$REPO`, run these before judging anything:

- `bash .claude/skills/fix-prose/scripts/check-suppressions.sh --diff` for what changed
- `bash .claude/skills/fix-prose/scripts/check-suppressions.sh --verify` for edits outside the target
- `cat` the target for the result in one piece

The diff is the review. Where it comes back empty, the fixer changed nothing, and that's a finding unless its report said so.

Where the caller passed the fixer's report, read it too. A claim there that the diff doesn't support is a finding in itself.

## What to check

Every finding names the exact text and the correction.

### Meaning

The document says what it said before.

- Flag any claim that changed. A dropped qualifier, an added hedge, or an absolute turned conditional edits the argument while looking like a reword.
- Flag any number, path, identifier, filename, flag, or proper noun that differs. These are never a style matter.
- Flag precision traded for a clean run. Replacing a dependency name with `the fuzzing dependency` clears a spelling rule and costs the reader the fact.
- Flag a clause or sentence that went missing. Deleting text clears a distributional rule and takes content with it.

### Language the linter can't score

The rule set names a few figurative verbs and misses the category around them.

- Flag metaphor, idiom, and personification that the edit introduced. Rules don't fight, checks don't bite, and a document doesn't sail anywhere.
- Flag a sentence that got longer without getting clearer. A reword that doubles a sentence to avoid a rule trades a measured problem for one nothing measures.
- Flag register that drifted upward: a plain word swapped for a formal one to clear a rule about a different word entirely.
- Flag anything the document didn't say before. Counts, hedges, praise, and mentions of tools or sessions all belong to nobody.

### The unresolved list

- Flag a finding reported as unresolvable that a plain reword clears. Say what the reword is.
- Accept an unresolvable finding that holds up. A rule misfiring on correct text is a real outcome, and demanding a fix for one is how documents get worse.

### Silenced checkers

The mechanical check already reports this, so read its output rather than re-deriving it. A `linter-config-changed` or `suppression-comment` finding there is automatically `CHANGES REQUIRED`.

## What to return

Return the verdict block and stop there. Skip the preamble, the summary of the diff, and the praise. Write nothing to disk, and don't edit the document to make it pass. Reporting the finding is the job.

```text
VERDICT: PASS
```

or

```text
VERDICT: CHANGES REQUIRED

1. [meaning] <what is wrong>
   text: <the exact offending text>
   fix:  <the specific correction>

2. [language] <what is wrong>
   text: <the exact offending text>
   fix:  <the specific correction>
```

Tag each finding `meaning`, `language`, `unresolved`, or `suppression`.

Return `PASS` when the edit holds up. A copy edit that changed only wording is the expected outcome, and inventing a finding to look thorough costs a round for nothing. Report only what you can point at in the diff.
