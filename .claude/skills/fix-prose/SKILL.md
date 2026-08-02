---
name: fix-prose
license: Apache-2.0
description: >-
  Clear the vale and cspell findings on a document whose content is already settled. A forked writer does the rounds and an independent reviewer reads the result, so the finding text never reaches this session. Takes the file plus the lint command that judges it. Use it when a draft is written but its prose gates are still red, or when a lint recipe has come back with findings more than once.
hooks:
  PreToolUse:
    - matcher: Write|Edit
      hooks:
        - type: command
          command: "${CLAUDE_PROJECT_DIR}/.claude/skills/fix-prose/scripts/guard-target.sh"
  PostToolUse:
    - matcher: Skill
      hooks:
        - type: command
          command: "${CLAUDE_PROJECT_DIR}/.claude/skills/fix-prose/scripts/arm-guard.sh"
---

# Clear the prose findings on a settled draft

Run two forked skills against each other until the document holds up. Findings, retries, and rejected wordings stay in their context rather than this one. That's the whole reason the skill exists. A twenty-line commit message can cost four rounds of vale output, none of it worth the context it occupies here.

Use it once the document says what it should say. The writer changes wording rather than claims, so a draft still arguing with itself needs its author instead.

## Preflight

!`bash ${CLAUDE_SKILL_DIR}/scripts/preflight.sh $ARGUMENTS`

Read the verdict before anything else. `BLOCKED` there means no agent can help. The file is missing, no rule set covers the path, or the document is already clean. Say which and hand back.

The preflight prints counts and verdicts rather than findings, on purpose. This body loads into your context rather than a fork, so a finding printed here enters the context the skill exists to keep clear.

## Arguments

`$ARGUMENTS` carries the file first, then the command that judges it.

```text
COMMIT_AGENTMSG just lint-commit-msg
PR_AGENTDESC.md just lint-pr-description
docs/design.md just lint-draft docs/design.md
```

The command comes from the caller because nobody else knows which gate applies. A commit draft answers to the commit-msg scope, and a description to its own recipe. Anything else takes `just lint-draft`, which runs vale and cspell and rumdl together over one file.

Prefer a recipe that runs every checker at once. `just lint-prose` runs vale alone, so a document clearing it can still fail spelling and structure, and a verdict from that recipe is narrower than it sounds.

Where the arguments name no file, ask which one. That first word is the path the guard protects. A run starting without it leaves the draft unprotected.

## Step 1: fix

Invoke `write-prose-fix`. It runs forked, and its own context block hands it the findings and the document, so it starts working rather than looking.

```text
Skill(write-prose-fix, args: "<target> <lint command>")
```

Pass nothing else in the arguments. The step that builds the writer's context substitutes them into a shell command line as raw text, so a semicolon runs, a parenthesis fails to parse, and an asterisk expands against the working directory. Findings text holds all three.

Where you have findings to hand over, write them to a file first and leave the arguments alone:

```bash
printf '%s\n' "<the reviewer's findings, verbatim>" > "$(git rev-parse --absolute-git-dir)/fix-prose.notes"
```

The writer's context prints that file and works from it. Remove it once the loop ends, so the next run starts clean.

Never edit the target yourself. A guard hook refuses it, because editing it here means reading the findings here.

It returns `PROSE: CLEAN`, `PROSE: PARTIAL` with a short unresolved list, or `PROSE: BLOCKED`.

## Step 2: check for silenced checkers

```bash
bash .claude/skills/fix-prose/scripts/check-suppressions.sh --verify
```

It compares the working tree against a baseline the guard recorded at invocation. Silence means the writer edited nothing but the target. Any output names a file it shouldn't have changed.

This runs here rather than inside the fork because an agent certifying its own work certifies nothing. The writer runs unguarded in there, so a style file or an inline `cspell:ignore` is within its reach, and both produce a clean lint run over a document nobody fixed. A finding means reverting that edit and taking the original lint finding back as unresolved.

## Step 3: review, and loop

Invoke `review-prose-fix`. It runs forked as an independent agent that saw neither the findings nor the edits, and it reads the before and after against each other.

```text
Skill(review-prose-fix, args: "<repository root> <target>")
```

The review exists because a clean lint run is a weak result on its own. Nothing in the gates scores a claim that moved, a name traded for a vaguer phrase, or a metaphor that arrived while somebody was clearing a rule. A document can pass every checker and come back saying something its author never wrote.

Its verdict drives the loop:

- `VERDICT: PASS` ends it. Report what changed and hand back.
- `VERDICT: CHANGES REQUIRED` returns to step 1, with the findings verbatim after the `--`.

Bound it at three rounds. Stop after that and report which findings keep returning, because a fourth pass at the same objection rarely helps.

## What to report

The unresolved list and nothing else. Each entry needs a decision that changes what the document claims, which is yours or the operator's rather than another lint round.

A rule misfiring on correct text arrives that way by design. The writer never turns a rule off or adds an exception, and never rewrites a sentence into nonsense to clear one. Overrule one by editing the target yourself. The guard prints its own release command for exactly that.
