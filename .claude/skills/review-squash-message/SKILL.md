---
name: review-squash-message
license: Apache-2.0
description: >-
  Review the squash commit message drafted in SQUASH_AGENTMSG against every commit it collapses, as an independent agent. Its distinct question is coverage. One message has to stand for a whole stack of commits, and this review asks what the collapse lost. Findings also cover claims the commits don't support, restating the diff, provenance filler, surviving Markdown, and a wrong subject reference. The merge-pr skill invokes this before every squash merge, passing the repository root.
context: fork
agent: Explore
background: false
---

# Review a squash commit message

Review a drafted squash message against the whole stack of commits it collapses, then return a verdict. You're the independent check. You didn't write this message and you didn't watch the branch happen, so read what it claims rather than what its author meant to claim.

Every other reviewer in this toolchain reads one text against one change, whether that's a commit message against its staged diff or a pull request description against its branch. This message has a harder job. It stands for a stack of commits that each carried a message of their own, and those messages disappear into it. Whether the collapse lost anything is the question only this review asks, and after the merge nothing remains to ask it of.

## The repository

`$ARGUMENTS` carries the repository under review. An empty value means the current working directory.

## Context

!`bash ${CLAUDE_SKILL_DIR}/scripts/context.sh $ARGUMENTS`

The preceding context carries everything the review needs. That means the draft, the commits it collapses with their bodies in full, the description as published, the changed files, and the diff. You are already at the repository root, so nothing below wants a `cd`.

Read the commit bodies rather than skimming the subjects.

A subject names what a commit did. The reason belongs in the body, and a reason is the first thing a squash loses.

Where the preceding context reports a missing or empty draft, a draft carrying no body, or a subject naming no pull request, that's itself a finding. Report it and stop.

Reach for a tool call only where the preceding material ran out, and say what you went looking for. A large branch truncates its diff at a stated line count, and a claim about the part beyond the cut needs `gh pr diff <number>` to settle.

## What's already settled

Gates run on either side of you. Repeating what they already cover wastes the round trip, so here is what they cover.

The commit-msg linters read this draft before this review and again after it. Subject length, line width, the Conventional Commits shape, trailer order, and spelling all answer to them. Leave every one of those alone.

The published description already passed its own review against this branch. Judge the message. Where the two disagree, the message is the text that merges, so treat the disagreement as a fact about the message rather than as a reason to reopen the description.

## What to check

Work these four groups. Every finding names the exact offending text and the fix.

### Coverage

This group is why the review exists. Take the commits one at a time and ask whether someone reading the message alone would know that work is in here.

- Flag a commit whose reason the message drops. Not its diff, its reason, meaning the constraint, or the problem its body named. That sentence goes with the commit at the merge, and nothing else records it.
- Flag a message that describes one commit as though it were the branch. The last commit and the largest commit are the ones that stand in for the rest.
- Flag a message that covers the early commits and stops. A branch that grew after someone published its description is the common case, and the message inherits the gap.
- Flag two commits giving different reasons where the message keeps only one. Either it covers both, or it says which one subsumes the other.
- Not every commit owes the message a sentence. A correction folded back in, or a formatting pass, landed as part of the work rather than as work of its own, and its absence is correct.
- Flag the reverse failure as well. A body that walks the stack commit by commit turns eight commits into eight paragraphs, where the branch deserves one account of what it did.

### Truthfulness

The body is new prose. No earlier review cleared it, so you are the first reader every claim in it gets.

- Flag any claim the commits and the diff don't support. A message naming a file, a flag, a behavior, or a guarantee absent from the branch is wrong, whatever else it gets right.
- Flag counts of any kind: files, lines, tests, commits, percentages. A count goes stale as soon as other work merges, and it pads a message rather than informing it.
- Flag results nobody verified: benchmark figures, `fixes the flake`, `no longer leaks`, claims about what CI does.
- Flag a claim the message inherited from the description that the branch has since outgrown. Commits pushed after publication are where this comes from.

### Substance

The body answers why the branch exists. The diff already carries what changed.

- Flag body text that restates the diff. `Adds a helper to foo.go and calls it from bar.go` describes a diff the reader can already read.
- Flag provenance filler: requests, review rounds, sessions, prompts, iterations, models, assistants, tools. Attribution belongs in the `Assisted-by` trailer and nowhere else.
- Flag selling: `robust`, `comprehensive`, `significantly`, `seamlessly`, `powerful`, `elegantly`, and their neighbors.
- Flag a body that repeats the subject in longer words.
- Verification notes belonged to the pull request, and their absence here is correct rather than a finding.
- Risk belongs here only where it names a rollback the reader wouldn't guess. Flag a risk sentence that says the change could be wrong and stops.

### Form

- Plain text throughout, with no fenced code blocks, headings, markdown emphasis, links, or tables. Backticks around a literal identifier are fine.
- Flag a body reading as a run of section titles from the description rather than as prose.
- Flag a subject missing its `(#<number>)` reference, or carrying the wrong number. The merge script reads that reference back, and a wrong one merges this message onto another pull request.
- Flag a `Closes` reference to something this branch doesn't close, and a missing one the description asked for. A cross-repository reference reduced to a bare number closes an unrelated local issue on merge.
- Flag a missing `Signed-off-by`, or an `Assisted-by` sitting after it rather than before.

## Sweep before you write the verdict

A gap you found once is rarely the only one. Take each finding you have and read the whole message again for the same kind of gap. A commit whose reason went missing, a claim the branch has outgrown, a count standing where a name belongs, a paragraph restating the diff. Where the message holds one, look for the second, and where instances share a fix, report them as a single finding naming each.

A gap you leave for the next pass costs a drafting round and a review round to say what this verdict could have said. None of that invites padding. Everything in the verdict still has to be something you can point at in the commits.

## What to return

Your verdict is what lets the merge proceed. A hook on the caller's side reads the line below and signs the draft you cleared. Keep the wording exact, because a verdict that hook can't parse leaves the merge blocked. Write nothing to disk yourself, and don't edit the draft to make it pass. Reporting the finding is the job.

Return the verdict block and stop there. Skip the preamble, the commit listing, and the praise.

```text
VERDICT: PASS
```

or

```text
VERDICT: CHANGES REQUIRED

1. [coverage] <what the message fails to account for>
   text: <the commit or the reason that went missing>
   fix:  <the specific correction>

2. [form] <what is wrong>
   text: <the exact offending text>
   fix:  <the specific correction>
```

Tag each finding `coverage`, `truthfulness`, `substance`, or `form`.

Return `PASS` when the message holds up. A message that really does stand for its whole stack counts as a real outcome, and inventing a finding to look thorough wastes the round trip. Report only what you can point at in the draft or in the commits behind it.
