---
name: review-squash-message
license: Apache-2.0
description: >-
  Review the conversion of a published pull request description into the squash commit message drafted in SQUASH_AGENTMSG, as an independent agent. Judges what the rewrite did to the text rather than what the text claims. Covers meaning dropped on the way across, surviving Markdown, a broken subject reference, and misplaced trailers. The merge-pr skill invokes this before every squash merge, passing the repository root.
context: fork
agent: Explore
background: false
---

# Review a squash message conversion

A published pull request description already passed an independent review before anyone published it. That review checked its claims against the diff, and squashing changes nothing about what the branch did. This one covers a single question instead: whether the conversion into a commit message kept faith with the description it came from.

Read both texts and return a verdict. Leave the description itself alone. A finding that the branch is incoherent, or that some claim overreaches, belonged to the review that ran before the pull request opened, and repeating it here wastes the round trip.

## The repository

`$ARGUMENTS`

Treat that path as the repository under review. An empty value means the current working directory.

```bash
REPO="${ARGUMENTS:-$(pwd)}"
```

## Gather the inputs

The draft's subject ends in the pull request number, so read the draft first and take the number from there.

- `cat "$REPO/SQUASH_AGENTMSG"` for the converted message
- `gh pr view <number> --json title,body` for the description it came from

Those two texts are the whole input.

A missing or empty draft, or a subject naming no pull request, is itself a finding. Report it and stop.

## What's already settled

The commit-msg linters run over this draft before and again after you, so leave their rules alone. Wrapping, subject length, the Conventional Commits shape, trailer order, and spelling all belong to them.

## What to check

Four questions, each about the gap between the two texts.

### Did meaning survive

- Flag a reason the description gives and the message drops. Summary and Why carry why the change exists, and a reader running `git log` needs that most.
- Flag a sentence the conversion garbled into something the description never claimed.
- Verification notes and reviewer pointers belonged to the pull request, so their absence is correct rather than a finding.

### Did Markdown survive

- Flag headings, fenced blocks, emphasis, link syntax, or tables still sitting in the message. Backticks around a literal identifier are fine.
- Flag a body reading as a list of section titles rather than as prose.

### Is the subject right

- Flag a subject missing its `(#<number>)` reference, or carrying the wrong number.
- Flag a subject the conversion truncated into something ungrammatical.

### Did the footer come across

- Flag a `Closes` reference the description asked for and the message dropped.
- Flag a closing reference to a number the description never mentioned.
- Flag a missing `Signed-off-by`, or an `Assisted-by` sitting after it rather than before.

## What to return

Your verdict is what lets the merge proceed. A hook on the caller's side reads the line below and signs the draft you cleared. Keep the wording exact, because a verdict that hook can't parse leaves the merge blocked. Write nothing to disk yourself, and don't edit the draft to make it pass.

Return the verdict block and stop there. Skip the preamble and the praise.

```text
VERDICT: PASS
```

or

```text
VERDICT: CHANGES REQUIRED

1. [meaning] <what the conversion lost or changed>
   text: <the offending text, or the description text that went missing>
   fix:  <the specific correction>
```

Tag each finding `meaning`, `markdown`, `subject`, or `footer`.

Return `PASS` when the conversion holds up. A faithful rewrite counts as a real outcome, and inventing a finding to look thorough wastes the round trip.
