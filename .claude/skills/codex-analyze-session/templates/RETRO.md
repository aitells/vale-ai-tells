# Retrospective: {{SESSION_ID}}

- Session: `{{SESSION_ID}}`
- Transcript: `artifacts/transcript.jsonl` ({{SIZE_MB}} MB, {{RECORDS}} records)
- Analyzed: {{ANALYZED}}
- Consensus: _n_/3 verifiers replicated the figures below

Replace this line with what the session actually cost and why. Start with the measurement, not the impression.

## Ranked patterns

Rank by round trips wasted, which `artifacts/loops.txt` reports. List frequency next to it, because a rare pattern costing twenty round trips ranks higher than a common one costing two.

| # | Pattern | Frequency | Round trips | Root cause | Fixable by |
| - | ------- | --------- | ----------- | ---------- | ---------- |

## Claims table

Every row went through three verifiers running the identical prompt. A row without a command in it never got replicated and doesn't belong here.

| claim | figure | command | consensus |
| ----- | ------ | ------- | --------- |

## Findings

Cite a line number for every claim, in `L1938` form. Where the session reached a conclusion, say whether it holds. A retraction the session made is a claim like any other, and needs the same test.

## Mechanical fixes

Prefer a script, a task, or a hook over an instruction. Number them in the order you would build them.

## Agent constructs

What the harness itself could fix. Use a proven hook or repository gate to enforce a rule that instruction can only request. Use a fresh delegated agent to keep work out of the calling context. Name the Codex facility exactly and confirm the installed harness supports it before recommending it.

| finding | construct | event or type | buys | costs |
| ------- | --------- | ------------- | ---- | ----- |

## Belongs in instruction, not tooling

## Inherent, accept rather than engineer around

Name what a strict gate costs by design. Removing this class of repeated work would cost more than accepting it.

## Method note

Record anything about how the analysis ran that affects how much a reader should trust it. A test that stopped checking anything belongs here, and so do agents that overwrote each other's files.

## Artifacts

The files under `artifacts/` are the evidence for this document. The canned reports come from `session.py`. Name any other evidence alongside them.

- `artifacts/transcript.jsonl` (the session transcript, copied for durability)
- `artifacts/index.txt` (record counts, tool histogram, failing-result lines)
- `artifacts/errors.txt` (every failing result, classified)
- `artifacts/loops.txt` (retry clusters ranked by round count)
- `artifacts/lint.txt` (rule frequency, and how many findings each run reported)
