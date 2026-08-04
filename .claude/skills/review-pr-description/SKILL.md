---
name: review-pr-description
license: Apache-2.0
description: >-
  Review a drafted pull request description in PR_AGENTDESC.md against the branch it would publish, as an independent agent, for what mechanical checking can't see. Covers claims the diff doesn't support, counting, provenance filler, restating the diff, a title describing one commit rather than the branch, and whether the branch is one coherent change. The pr skill invokes this before opening every pull request, passing the repository root.
context: fork
agent: Explore
background: false
---

# Review a drafted pull request description

Review a drafted pull request description against the branch it would publish, then return a verdict. You're the independent check. You didn't write this description and you didn't watch the work happen, so read what it claims rather than what its author meant to claim.

## The repository

`$ARGUMENTS`

Treat that path as the repository under review. An empty value means the current working directory. Bind it once and use it throughout:

```bash
REPO="${ARGUMENTS:-$(pwd)}"
```

## Gather the inputs

Run these before judging anything:

- `cat "$REPO/PR_AGENTDESC.md"` for the draft
- `sed -n '/^base:/p' "$REPO/PR_AGENTDESC.md"` for the base branch the rest of these need
- `git -C "$REPO" log --reverse --pretty=format:'--- %h%n%B' <base>..HEAD` for the commits that would land
- `git -C "$REPO" diff --name-status <base>...HEAD` for the paths
- `git -C "$REPO" diff <base>...HEAD` for the diff itself
- `cat "$REPO/.github/pull_request_template.md"` for what each section is asking

A missing or empty draft, or a branch with nothing to land, is itself a finding. Report it and stop.

## What's already settled

The writer clears a mechanical validator before handing you anything, and the caller runs it again afterwards, so leave its rules alone. It has already settled:

- the frontmatter shape, and the title's length and Conventional Commits form
- section presence, section order, and sections left empty
- surviving template comments, unclosed fences, and links pointing nowhere
- whether every path the draft puts in backticks exists

Repeating any of that wastes the round trip.

Read the diff instead. Your job starts where looking at the file stops.

## What to check

Work these four groups. Every finding names the exact offending text and the fix.

### Truthfulness

The description covers this branch and no other.

- Flag any claim the diff doesn't support. A description naming a behavior, a flag, or a guarantee absent from the diff is wrong, whatever else it gets right.
- Flag counts of any kind: files, lines, tests, commits, percentages. A count goes stale the moment other work merges, and it pads a description rather than informing it.
- Flag results nobody verified. The Verification section names commands, so check that the commands suit the change. A Go change verified only by a Markdown linter reports nothing about itself.
- Flag a Risk section that says nothing risks anything when the diff touches behavior, and flag invented risk when the diff touches documentation alone.

### Substance

Each section answers its own question, and the template says which.

- Flag a Summary that restates the diff. `Adds a helper to foo.go and calls it from bar.go` describes a diff the reader can already read.
- Flag a Why that repeats the Summary in longer words, or that explains nothing a reader couldn't recover from the diff.
- Flag provenance filler: requests, review rounds, sessions, prompts, iterations, models, assistants, tools. None of that belongs in a description.
- Flag selling: `robust`, `comprehensive`, `significantly`, `seamlessly`, `powerful`, `elegantly`, and their neighbors.

### Fit

The description covers the whole branch, not the commit its author happened to write last.

- Flag a title describing one commit when the branch carries more than one. That title becomes the squash subject on the default branch, so it names what the whole branch does.
- Flag a Summary that covers some commits and drops others.
- Flag labels that misreport the change: a documentation label on a branch touching behavior, or a bug label on a branch fixing nothing.
- Flag `draft: false` on a branch whose own description says the work is unfinished.

### Coherence

Judge the branch, not the description.

- Does the branch carry one change, one a reviewer can hold in their head, one that merges or reverts as a unit?
- Flag a branch mixing unrelated work, and name the pull requests it should split into. Reviewers miss things in a branch that changed three unrelated areas.
- A change plus its tests, or a change plus the documentation describing it, counts as one change. Leave that alone.
- Size alone isn't a finding. A wide mechanical rename counts as one change. A small diff touching two unrelated subsystems doesn't.

## Sweep before you write the verdict

A fault you found once is rarely alone. Take each finding you have and read the whole draft again for the same fault. A list that stops short of the diff, a claim scoped wider than the evidence, a count standing where a name belongs, a sentence selling rather than saying. Where the draft holds one, look for the second. Where instances share a fix, report them as a single finding naming each.

Do this even when a finding sends you back into a section you already cleared. The draft in front of you changed since the last pass, and a claim that held then may not hold now.

An instance you leave for the next pass costs a writer round and a reviewer round to say what this verdict could have said. None of that invites padding. Everything in the verdict still has to be something you can point at.

## What to return

Your verdict is what lets the pull request proceed. A hook on the caller's side reads the line below and signs the draft you cleared. Keep the wording exact, because a verdict that hook can't parse leaves the pull request blocked. Write nothing to disk yourself, and don't edit the draft to make it pass. Reporting the finding is the job.

Return the verdict block and stop there. Skip the preamble, the diff summary, and the praise.

```text
VERDICT: PASS
```

or

```text
VERDICT: CHANGES REQUIRED

1. [truthfulness] <what is wrong>
   text: <the exact offending text>
   fix:  <the specific correction>

2. [coherence] <what is wrong>
   text: <the exact offending text>
   fix:  <the specific correction>
```

Tag each finding `truthfulness`, `substance`, `fit`, or `coherence`.

Return `PASS` when the draft holds up. A clean description counts as a real outcome, and inventing a finding to look thorough wastes the round trip. Report only what you can point at in the draft or the diff.

Your findings go straight back to `write-pr-description` as its next instructions, so write each one so that agent can act on it without seeing this conversation. Name the section and quote the offending text, then give the replacement.
