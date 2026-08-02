---
name: review-commit-message
license: Apache-2.0
description: >-
  Review a drafted commit message in COMMIT_AGENTMSG against the staged diff, as an independent agent, for the things mechanical linting can't see: claims the diff doesn't support, counting, provenance filler, restating the diff, subject mood and bounds, plain-text form, and whether the staged change is one logical change. The commit skill invokes this before every commit, passing the repository root.
context: fork
agent: Explore
background: false
---

# Review a drafted commit message

Review a drafted commit message against its staged diff and return a verdict. You're the independent check. You didn't write this message and you didn't watch the work happen, so read what the message claims rather than what its author meant to claim.

## The repository

`$ARGUMENTS`

Treat the first word as the repository under review. An empty value means the current working directory. Bind it once and use it throughout:

```bash
REPO="${ARGUMENTS:-$(pwd)}"
```

A second word of `--amend` says this commit replaces the one at `HEAD` instead of following it. That changes which diff you read, and nothing else about your job.

## Gather the inputs

Run these before judging anything:

- `cat "$REPO/COMMIT_AGENTMSG"` for the draft
- `git -C "$REPO" diff --cached --name-status` for the staged paths
- `git -C "$REPO" diff --cached` for the staged diff
- `git -C "$REPO" log -5 --pretty=format:'%h %s'` for house style

Where the caller passed `--amend`, swap the two staged-diff commands for these:

- `git -C "$REPO" diff --cached --name-status HEAD~1`
- `git -C "$REPO" diff --cached HEAD~1`

Those show the amended commit's full contents, meaning the existing commit plus whatever the author has staged since. Reading the plain staged diff during an amend shows the delta alone, so a message describing the whole commit looks like it claims things the diff never supported. That mistake produces confident, wrong findings.

A missing or empty draft, or an empty staged diff, is itself a finding. Report it and stop.

## What to check

Work these four groups. Every finding names the exact offending text and the fix.

### Truthfulness

The message describes this diff and no other.

- Flag any claim the staged diff doesn't support. A message that mentions a file, function, flag, or behavior absent from the diff is wrong, whatever else it gets right.
- Flag counts of any kind: files, lines, tests, functions, commits, percentages. A count goes stale as soon as other work merges, and it pads a message rather than informing it.
- Flag results nobody verified: benchmark figures, `fixes the flake`, `no longer leaks`, claims about what CI does.

### Substance

The body answers why the change exists. The diff already carries what changed.

- Flag body text that restates the diff. `Adds a helper to foo.go and calls it from bar.go` describes a diff the reader can already read.
- Flag provenance filler: requests, review rounds, sessions, prompts, iterations, models, assistants, tools. Attribution belongs in the `Assisted-by` trailer and nowhere else.
- Flag selling: `robust`, `comprehensive`, `significantly`, `seamlessly`, `powerful`, `elegantly`, and their neighbors.
- Flag a body that repeats the subject in longer words, or that explains nothing the reader couldn't recover from the diff.

### Form

- Subject shape `<type>(<scope>)?(!)?: <description>`, with a type that suits the change: `docs` for documentation, `feat` for a new capability, `fix` for a defect, `refactor` for behavior-preserving work.
- Subject in imperative mood and present tense: `explain the tools`, never `explains`, `explained`, or `explaining`.
- No trailing period on the subject. Subject length between 10 and 80 characters.
- Body lines wrap at 72 characters. Footer and trailer lines wrap at 100.
- Plain text throughout, with no fenced code blocks, headings, markdown emphasis, links, or tables. Backticks around a literal identifier are fine.
- `Assisted-by` appears before `Signed-off-by`. No model or assistant credited through `Co-authored-by`.

### Atomicity

Judge the staged diff, not the message.

- Does it carry one logical change, one the reader can state in a sentence, one that reverts cleanly as a unit?
- Flag a diff that mixes a behavior change with an unrelated refactor, a fix with a formatting sweep, or two independent features. Name the groups it should split into.
- A change plus its tests, or a change plus the documentation describing it, counts as one logical change. Leave that alone.

## What to return

Your verdict is what lets the commit proceed. A hook on the caller's side reads the line below and signs the draft you cleared. Keep the wording exact, because a verdict that hook can't parse leaves the commit blocked. Write nothing to disk yourself, and don't edit the draft to make it pass. Reporting the finding is the job.

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

2. [form] <what is wrong>
   text: <the exact offending text>
   fix:  <the specific correction>
```

Tag each finding `truthfulness`, `substance`, `form`, or `atomicity`.

Return `PASS` when the draft holds up. A clean message counts as a real outcome, and inventing a finding to look thorough wastes the round trip. Report only what you can point at in the draft or the diff.
