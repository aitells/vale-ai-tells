---
name: write-prose-fix
license: Apache-2.0
description: >-
  Rewords a document to clear its lint findings. The fix-prose skill invokes this by name.
context: fork
agent: general-purpose
background: false
---

# Clear the prose findings, and change nothing else

Clear the lint findings on one file by rewording it. Someone has already decided what the document says, and that part stays fixed. Change how it reads, and only as far as the findings require.

## Context

!`bash ${CLAUDE_SKILL_DIR}/scripts/context.sh $ARGUMENTS`

## The one rule

Leave the meaning alone. Every claim the document makes survives your pass intact, and so does every number, path, identifier, and name in it.

A finding you can only clear by saying something different is a finding you leave alone. Report it instead. Inventing a claim to please a linter is the worst outcome available here, because it reads as clean and puts words into the document that nobody wrote.

Reword. Don't rewrite.

## Your inputs

`$ARGUMENTS` carries the target first, then the command that judges it. Anything after a `--` is what the caller wants addressed, which on a second pass is the findings `review-prose-fix` returned. Treat those as the work: resolve each and say so.

The context below already ran the command and printed the document, so the findings and the text are both in front of you. Don't re-run the command to see them again.

## The loop

1. Read the findings in the preceding context. Count them.
2. Fix the whole list in one editing pass, cheapest findings first, editing only the target.
3. Run the lint command again. Compare the count.

Never re-run after a single edit. Each round costs the same whether it clears one finding or twelve, and the session behind this skill spent half its Bash calls on linters it re-ran a fix at a time.

Stop at any of these:

- The command prints nothing, having printed something earlier. Read the next section before you trust that.
- The count fails to drop across two runs in a row.
- A finding you already cleared comes back. Something you wrote to clear one rule is tripping another, and a third pass at the same pair rarely helps.
- The loop has run five times.

The session this skill exists for spent thirty-one rounds on one commit message. Stopping early costs the caller a short unresolved list, and continuing costs them the context this skill exists to save.

## Silence proves nothing on its own

A checker that never ran and a document with nothing wrong print exactly the same thing.

Vale matches a path against the sections in `.vale.ini`, and the match is exact. A path no section names loads no styles at all, so vale reads the file and applies nothing to it. Silence and a zero exit code follow. Measured against this repository, one paragraph of deliberately bad prose draws 13 findings as `probe.md` and draws zero as `probe.txt`, zero under a different filename, and zero at the same filename one directory down.

The preceding context answered this before you started. It pushed known-bad text through vale under this document's own path and reported whether the rules are live, so read that line rather than reasoning about it. Where it says `UNSCOPED`, report `BLOCKED` and stop. For a run where it went missing, your first lint run is what answers the question:

- The first run reports findings. The command demonstrably fires, so a later silence is real, and clearing the list gives you `CLEAN`.
- The first run is silent. You've learned nothing yet. Report `BLOCKED` and say the document may already be clean or the command may not cover this path. Never report `CLEAN` off a silence you haven't seen the command break.

A commit draft is the common case. The section covering one names the file at the repository root, so a draft anywhere else, or under any other name, passes every gate unchecked.

## What the linter can't see

The rule set names a few figurative verbs and misses the category around them. `ai-tells.FigurativeLands` catches `text lands in`. Nothing catches `where this bites`, `sails through every gate`, `moving the goalposts`, or `its blast radius`, and every one of those phrases cleared every gate in this repository while somebody was writing the file you are reading now.

Rewording is the whole task here, which makes this run the most likely place for a phrase the gates were never going to question to enter the document.

These hold even though nothing enforces them:

- Write literally. Metaphor, idiom, and personification are all out. Rules don't fight, checks don't bite, and a document doesn't sail anywhere.
- Keep the register plain. A concrete noun and an active verb beat a vivid pair.
- Don't lengthen. A reword that doubles a sentence to avoid a rule makes the document worse in a way nothing measures.
- Don't drop precision. Swapping a specific name for a vague phrase clears a spelling rule and costs the reader the fact.
- Don't reorder or delete content for a distributional rule. Splitting a sentence is structural. Cutting a clause edits meaning.
- Don't add what the document didn't say. That covers counts, hedges, praise, and any mention of tools, sessions, or requests.

No linter checks these. An independent reviewer does, reading your before and after against each other, and its findings come back to you in `also:` for another pass. Getting them right the first time is what keeps that loop to one round.

## Reading the output

The vale recipes print one self-contained line per finding:

```text
12:5-19 [error] Google.Contractions match="do not" replace_with="don't" msg="Use 'don't' instead of 'do not'."
```

Everything you need is on that line. `match` gives the exact offending text. `replace_with` appears whenever the rule includes a replacement, and applying it verbatim beats composing your own. Read the line. Don't search for context the line already contains.

cspell prints its own shape, one line per unknown word with a location.

## Findings that cost nothing

Run this first, before you read the findings at all:

```bash
just fix-prose-replacements <target>
```

It applies every finding whose rule carries its own correction, which is roughly a third of a typical run. Contractions, WordList, Semicolons, Ellipses, Ranges, and HeadingPunctuation all qualify. It refuses any finding whose span no longer holds the text the report quoted, so a stale report skips rather than corrupts the line.

What it leaves is the part that needs you. Reading a lookup so you can retype its answer is the cheapest habit to drop here.

## Findings that resist a local fix

Some rules judge a whole block rather than a phrase. The experimental set is where they live: sentence length variance, paragraph length variance, sentence-start repetition, sentence-start entropy, average sentence length, passive density, complex word density, content duplication, transition repetition, and the document-level verb-series count.

Any local edit changes the distribution, so clearing one can trigger a related rule. That antagonism is inherent rather than a defect you can edit around.

Fix them structurally, never by changing content:

- Split a long sentence into two.
- Merge two short ones.
- Change the word a sentence opens with.
- Let one paragraph run short among longer ones.

Give any one of these two attempts. Report it after that.

## Rules nothing can clear

`ai-tells.VerbTricolon` misfires, and a commit message is where it appears most often. The rule looks for three parallel verb phrases in a comma series. Nothing bounds its match to a sentence or a paragraph, and one branch of the rule anchors on a colon, so the `:` in a Conventional Commits subject counts the subject's verb as part of a series that doesn't exist. Commas placed the wrong way in the body are enough.

It triggers on either shape:

- a comma series whose last separator is `, and`
- a colon followed by two later commas

Both span sentence and paragraph boundaries.

The fix that keeps meaning is fewer commas. Splitting a comma clause into two sentences clears it outright, and the prose improves more often than not. Where the sentence really needs its commas, report the finding and say the rule is misfiring. A correction is coming upstream in `tbhb/vale-ai-tells`.

Treat any rule this way once you've established that nothing clears it. Report it, name what you tried, and leave the text correct.

## Spelling

Correct a real misspelling. That's the easy half.

The other half is a token cspell doesn't know but the document is right to use, such as a dependency name, a proper noun, or an acronym. Adding it to `.cspell-words.txt` edits a shared project file, which isn't yours to decide. Where naming the concept instead keeps the claim exactly as strong, prefer that: `the fuzzing dependency` clears both the spelling and the acronym rules. Where the specific token is the point, report the finding along with the line somebody would add.

## Never

- Edit any file except the target. You may not edit the linter configuration, which covers `.vale.ini`, the `.vale/` styles, `.cspell.jsonc`, `.cspell-words.txt`, the Justfile, and the hook configuration.
- Add an inline vale exception, or turn a rule off anywhere. Clearing a finding by silencing its rule is the one thing that must never happen here.
- Change the target's wrapping convention. Markdown in this repository puts each paragraph on a single line and a hook enforces it. A commit message wraps its body at 72 columns and its trailers at 100.
- Touch anything inside a fenced code block, a path, or a backticked identifier.
- Edit the target through `sed`, `awk`, or a shell redirect. Use the file editing tools. This machine runs a hybrid toolchain: `sed` is GNU, `cat` is BSD, and `timeout` is absent. The session behind this skill spent four round trips on commands whose variant it guessed wrong.

A script verifies these after you return, comparing the working tree against a baseline recorded before you started. It hashes the style packages directly rather than asking git, so an edit to one git never tracks shows up the same as any other. Reporting a finding you couldn't clear takes one line. Silencing it forces the caller to revert your edit and answer the finding regardless.

## What to return

Return the block and stop there. Skip the preamble, the running commentary, and the praise. Whoever reads this started the run precisely so they wouldn't have to see the rounds.

```text
PROSE: CLEAN

changed: <one line per class of edit>
```

or, where something survived:

```text
PROSE: PARTIAL

changed: <one line per class of edit, or "nothing">
unresolved:
1. [<rule>] <line>: <the exact text>
   why: <what clearing it would cost, in one line>
2. ...
```

or:

```text
PROSE: BLOCKED

reason: <what stopped you>
```

`BLOCKED` covers a target that doesn't exist, a lint command that fails to run, and a first run that printed nothing. That last one means the document was already clean or the command never covered it, and saying which takes a look the caller has to make. It doesn't cover findings you simply haven't worked yet.

Keep `unresolved` short and specific. Each entry is a decision someone has to make, so give them the text and the cost rather than a paragraph about the rule.
