---
name: analyze-session
license: Apache-2.0
description: >-
  Query a Claude Code transcript without reading it into context, then write the retrospective to disk so it remains available after the session ends. The tool reads the file line by line and reports every failure and repeated tool call by line number. Use this skill when the user asks for a retrospective on a past session, or hands over a transcript path with a question about it.
---

# Analyze a session

Work the steps in order. This skill ends once the retrospective exists on disk and the operator has its path. Acting on what it recommends is separate work, and the `commit` skill owns whatever lands as a change.

## Which session

`$ARGUMENTS` holds the absolute path to the transcript. A bare session ID also works, provided it names exactly one file under `~/.claude/projects/`.

If you give neither, the preflight says so and prints how to find it. Send a Haiku subagent, then run the preflight again with the path it returns. Never search the projects directory yourself. Reading transcripts to find one costs more context than the entire analysis that follows it.

## Preflight

!`bash ${CLAUDE_SKILL_DIR}/scripts/preflight.sh ${ARGUMENTS}`

## Step 0: open the task list

Create these tasks with `TaskCreate`, then move each to `in_progress` and `completed` as you go. They're the checklist the rest of this document expands.

1. Read what the line numbers identify
2. Test the session's own conclusions
3. Verify every figure with three agents
4. Recommend fixes across the five areas
5. Write the retrospective

Stop before any of it where preflight couldn't resolve the transcript, or reports a missing precondition. Say what's wrong and hand back.

The preflight already resolved the transcript and summarized the session. It created the retro directory at `<main worktree>/.claude/retros/YYYYMMDD_<session ID>/` and copied the evidence into it. Read that report before forming any hypothesis, because it writes everything it prints to `artifacts/` as well, where a later reader can check it.

`.claude/skills/analyze-session/references/SESSION_CLI.md` documents every subcommand, for when a report needs more detail than the preflight printed.

## Step 1: read what the line numbers identify

The preflight listed the failing lines and the line ranges of each repeated sequence. Open those, and nothing else:

```text
.claude/skills/analyze-session/scripts/session.py grep <transcript> 'pattern' --context 300
.claude/skills/analyze-session/scripts/session.py show <transcript> 361,408,1938
```

`grep` searches the decoded content blocks, so what prints matches what the model saw. Add `--kind THINK` to read what the agent believed at the time, which is often where an error begins. `show` prints whole records, once a report has given you a specific line number.

## Step 2: test the session's own conclusions

A transcript records what an agent believed, which isn't always what was true. Treat every claim in it as a hypothesis with a line number attached, including the agent's own corrections.

Re-run the decisive command wherever that environment still exists.

**Check that a test can fail before trusting a result of zero.** A test returning nothing may mean the thing is absent, or may mean the test stopped examining anything. Give it a case that must produce output, and treat an empty result as evidence only after that check passes. A test that has stopped examining anything reports nothing whatsoever, where a working one still returns unrelated findings alongside the empty answer.

## Step 3: verify every figure with three agents

Readers trust a number more than a description, so a wrong count does more damage than a wrong impression. No figure reaches the operator without independent replication.

Follow `.claude/skills/analyze-session/references/VERIFY_FIGURES.md`. It gives the claims table format, the prompt each verifier receives, the isolation rule for verifiers that write files, and how to settle a figure they disagree on.

Hold every figure until all three report. A verifier that hasn't answered yet isn't an abstention, and counting it as one discards the report most likely to disagree.

## Step 4: recommend fixes across the five areas

Step 3 runs identical prompts, because replication gains nothing from a division of labor. This step does the opposite, giving each agent one area so the recommendations stay distinct.

Follow `.claude/skills/analyze-session/references/FIX_SURFACES.md`. It names the five areas, the shared prompt, and the block each agent receives.

Synthesize the results yourself. Each agent sees one area, while this session has the verified figures and the full set of findings no single agent had.

## Step 5: write the retrospective

Fill in the `RETRO.md` the preflight created, following `.claude/skills/analyze-session/references/WRITING_THE_RETRO.md`.

Cite a line number for every claim. Rank findings by round trips wasted rather than by how irritating they were. State what each fix costs as well as what it improves, and give the operator the retro path when you report back.

## Preconditions

This skill assumes the shared tbhb toolchain:

- `uv` on PATH, which the `session.py` shebang uses to select an interpreter
- a git repository, because the retro directory resolves from the main checkout
- a transcript path in `$ARGUMENTS`, or a session ID naming exactly one file

Preflight checks each. Where one is missing, tell the operator rather than improvising a substitute.
