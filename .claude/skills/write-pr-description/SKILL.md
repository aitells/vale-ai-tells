---
name: write-pr-description
license: Apache-2.0
description: >-
  Write or revise the pull request description in PR_AGENTDESC.md, as a forked agent that reads the branch itself. Fills the frontmatter properties, a Conventional Commits title, and every section the repository's template declares, then clears the mechanical validator before returning. The pr skill calls this to draft, fix-pr calls it after remediation commits arrive, and merge-pr calls it for a final pass. Every call pairs with review-pr-description afterwards.
context: fork
agent: general-purpose
background: false
---

# Write a pull request description

Write `PR_AGENTDESC.md` at the repository root, then return. You run forked, so the branch diff sits in your context rather than the caller's. Read the material below and write from it.

## Arguments

`$ARGUMENTS` carries the repository root, and after it whatever the caller wants addressed. A first draft arrives with nothing extra. A revision arrives carrying the findings `review-pr-description` returned, or a note that remediation added commits the description hasn't caught up with.

Treat any findings in the arguments as the work. Resolve each one and say so.

## Context

!`bash ${CLAUDE_SKILL_DIR}/scripts/context.sh`

## The shape

Write the file in exactly this order.

```text
---
base: <branch this merges into>
draft: <true or false>
labels: [<one or more from the set above>]
reviewers: []
assignees: []
milestone:
---

# <type>(<scope>)?: <description>

## <first template section>

<prose>
```

Those frontmatter keys and no others. Labels take a flow sequence and an empty one fails the validator, because nobody's filter finds an unlabelled pull request.

The title is a level 1 heading in the Conventional Commits shape. A squash merge turns it into the commit subject on the default branch, so its type has to be one the landing commits use, and it names what the whole branch does rather than what the last commit did.

Then every section the template declares, in the template's order, filled with prose. Replace each instructional comment rather than leaving it in place.

## What each section owes the reader

The sections answer different questions, so don't let them repeat each other. Summary says what changes. Why says what problem made it necessary. Verification names the commands you actually ran, in backticks. Risk says what breaks if this is wrong and how to back it out. Related points at issues, or says `None`.

Avoid:

- Restating the diff. A reviewer reads the diff already.
- Counting. No file, line, test, or commit counts.
- Provenance filler. Nothing about requests, sessions, prompts, models, or tools.
- Claims you haven't checked, including verification nobody ran.
- Selling it. Drop `robust`, `comprehensive`, `significantly`, and their neighbors.
- Paths that don't exist. Every backticked path gets resolved against the tree and the diff.

## Revising rather than starting over

Where a draft already exists, the context printed it earlier. Keep the sentences that still hold. A revision that rewrites untouched prose costs the caller another review round for nothing, and it loses wording an earlier review already cleared.

A finding names one instance of a fault rather than the fault itself. Fix the instance, then read the rest of the draft for the same fault, because a reviewer that found one instance finds the next one on the next round. That sweep isn't the rewriting this section warns against, since it changes a sentence only where the sentence is wrong.

Where the published description differs from the draft, the branch has moved since the last publish. Bring the draft forward rather than reverting it to what GitHub shows.

## Read the draft back before returning

The validator covers what a script can check. What follows is what the reviewer sends drafts back for, and the context printed earlier already holds the answer to each, so a round trip spent on one buys nothing.

**Closed enumerations.** A sentence naming the kinds of change on the branch claims to name every one, and a reviewer reads it that way. Walk the changed-file listing against every sentence of that shape, and confirm the sentence covers each path or that you left the path out on purpose. Where you can't confirm it, write the sentence open, so it claims only what you checked.

**Scope words.** `only`, `every`, `never`, and `the one place` each make a claim about the files you didn't quote. Open the file and establish the scope before writing one. A setting described as mattering on a single CI slot is a claim about every other slot, and the workflow in the diff either bears that out or doesn't.

**The Avoid list earlier in this document.** Read the finished draft against it once. Following a rule while writing and satisfying it in the finished text are different things.

## Clear the validator before returning

```text
bash .claude/skills/pr/scripts/validate-description.sh
```

Run it, fix every finding, and run it again until it prints nothing. Each finding names a line and the correction.

Returning a draft that fails the validator spends a review round on something a script settles by itself, and the caller only has to send you back, so treat this as part of writing rather than a step after it.

## What to return

Return this block and stop there. Skip the preamble and the praise, and leave the description itself for the caller to read off disk.

```text
DRAFT: WRITTEN

changed: <what you altered, one line per item, or "first draft">
addressed: <each finding from the arguments and how, or "nothing requested">
```

or, when the branch or the repository makes drafting impossible:

```text
DRAFT: BLOCKED

reason: <what stopped you>
```

Blocked covers a branch with nothing to land, a missing template, and a validator finding you can't resolve without a decision the caller has to make. It doesn't cover a validator finding you simply haven't fixed yet.
