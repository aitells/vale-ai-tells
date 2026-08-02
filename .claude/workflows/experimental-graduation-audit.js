// 2.0 Phase 0: decide, per experimental rule, promote-to-core / keep-as-metrics / retire.
// Context: 2.0 moves graduating rules into styles/ai-tells/ at level: error, renames the
// remaining style (working name: ai-tells-metrics) for permanent threshold heuristics,
// and prefixes the Tengo scripts (Vale dumps them flat into config/scripts, so they need
// a package prefix to be gitignorable next to user-owned scripts). Retirements shrink
// the rename surface. Run with: Workflow({name: 'experimental-graduation-audit'})
export const meta = {
  name: 'experimental-graduation-audit',
  description: 'Evaluate each ai-tells-experimental rule for promotion to core, retention as a metrics-tier rule, or retirement, ahead of 2.0',
  whenToUse: 'Phase 0 of the 2.0 release: decides the fate of all 18 experimental rules before the core migration and Tengo rename.',
  phases: [
    { title: 'Evaluate', detail: 'one agent per rule: read, test on human + AI prose, recommend', model: 'opus' },
    { title: 'Challenge', detail: 'skeptic reviews each promote/retire call', model: 'opus' },
    { title: 'Synthesize', detail: 'population sanity: resulting styles, overlaps, rename surface' },
  ],
}

const REPO = '/Users/tony/Code/github.com/tbhb/vale-ai-tells'

const RULES = [
  'AverageSentenceLength', 'ComplexWordDensity', 'ContentDuplication',
  'ContractionAvoidance', 'FigurativeAnchor', 'HeadingTitleCase', 'LongWordDensity',
  'ParagraphLengthVariance', 'PassiveDensity', 'PassiveVoice', 'PassiveVoiceAdverb',
  'SentenceLengthVariance', 'SentenceStartEntropy', 'SentenceStartRepetition',
  'TransitionRepetition', 'TricolonDensityDocument', 'VocabularySwap',
]

const GOTCHAS = `Vale 3.14.2, Go regex (no lookbehind/backrefs). Scratch test files MUST live in the repo
root (files elsewhere get empty BasedOnStyles); experimental rules are level: warning, so use a scratch INI
with MinAlertLevel = suggestion enabling ai-tells-experimental. DELETE every scratch file when done. Never
modify tracked files. Tengo-backed rules read their scripts from styles/config/scripts/.`

const CRITERIA = `Recommend exactly one of:
- "promote": moves into styles/ai-tells/ at level: error in 2.0. Requires ALL of: (a) deterministic
  tell-matching (existence/sequence/substitution/capitalization), not a tunable threshold; (b) acceptably rare
  false positives on genuinely human technical prose when treated as a hard error (repo policy: flag hard, no
  built-in exception lists, but wrong-sense matches on ordinary human prose disqualify); (c) no unresolved
  double-flag overlap with a core rule or with the bundled write-good/proselint/Google styles, or a concrete
  dedup plan; (d) message can be made to fit the core template "AI <label>: '%s'. <concrete action>." and pass
  mise run lint-messages.
- "keep-metrics": stays in the renamed metrics tier at level: warning. For document-level/threshold/statistical
  heuristics that are useful signals but wrong as hard errors. State whether the current threshold is sensible.
- "retire": delete in 2.0. For rules that are redundant with core or bundled styles, unsound, or not actually
  indicative of AI prose.

Method (empirical, not vibes): read the rule file fully including comments (they document intent and known
limitations). Write TWO scratch fixtures in the repo root: one of realistic HUMAN-written technical prose you
compose (vary register: README, runbook, design doc, changelog) and one of characteristic AI-sloppy prose.
Run vale with your scratch INI on both. A promote recommendation must show the AI fixture fires and the human
fixture stays clean (or explain every human-side hit as a true tell). Also grep core styles/ai-tells/ and the
synced write-good/proselint styles for overlapping coverage. Known overlaps to address explicitly:
VocabularySwap duplicates OverusedVocabulary/FormalRegister/OverusedVocabularyVerbs entries (delve, leverage,
utilize, facilitate, ...) — promotion means merging or splitting ownership; PassiveVoice/PassiveVoiceAdverb
overlap write-good.Passive.`

const EVAL_SCHEMA = {
  type: 'object',
  properties: {
    rule: { type: 'string' },
    recommendation: { type: 'string', enum: ['promote', 'keep-metrics', 'retire'] },
    confidence: { type: 'string', enum: ['high', 'medium', 'low'] },
    mechanism: { type: 'string', description: 'extends type + whether Tengo-backed (script filename if so)' },
    humanFalsePositives: { type: 'string', description: 'What fired on the human fixture, verbatim spans, or "clean"' },
    aiTruePositives: { type: 'string', description: 'What fired on the AI fixture' },
    overlaps: { type: 'string', description: 'Core/bundled-style rules covering the same ground, with tokens' },
    migrationNotes: { type: 'string', description: 'If promote: message rework, level change, merges needed. If keep: threshold sanity. If retire: what replaces it, if anything' },
    reasoning: { type: 'string' },
  },
  required: ['rule', 'recommendation', 'confidence', 'mechanism', 'humanFalsePositives', 'aiTruePositives', 'overlaps', 'migrationNotes', 'reasoning'],
}

const CHALLENGE_SCHEMA = {
  type: 'object',
  properties: {
    agrees: { type: 'boolean' },
    finalRecommendation: { type: 'string', enum: ['promote', 'keep-metrics', 'retire'] },
    reasoning: { type: 'string', description: 'What you re-tested and why you agree or overturn' },
  },
  required: ['agrees', 'finalRecommendation', 'reasoning'],
}

const results = await pipeline(
  RULES,
  rule => agent(
    `Evaluate the Vale rule styles/ai-tells-experimental/${rule}.yml in ${REPO} for the 2.0 graduation decision.\n\n${CRITERIA}\n\n${GOTCHAS}\n\nAlso consult EXPERIMENTAL.md's entry for this rule and the audit history in AUDIT_PLAN.md if present. Your final output is machine-consumed structured data.`,
    { label: `eval:${rule}`, phase: 'Evaluate', schema: EVAL_SCHEMA, model: 'opus' }
  ),
  (ev, rule) => {
    if (!ev) return null
    // keep-metrics is the safe default; only the moves in either direction need an adversary.
    if (ev.recommendation === 'keep-metrics' && ev.confidence === 'high') return { ...ev, challenged: false }
    return agent(
      `Adversarially review this graduation call for Vale rule styles/ai-tells-experimental/${rule}.yml in ${REPO}. Default stance: the recommendation is WRONG until its evidence survives your own testing.\n\nRecommendation: ${ev.recommendation} (confidence ${ev.confidence})\nHuman-fixture FPs claimed: ${ev.humanFalsePositives}\nAI-fixture hits claimed: ${ev.aiTruePositives}\nOverlaps claimed: ${ev.overlaps}\nReasoning: ${ev.reasoning}\n\nIf "promote": hunt for human-prose false positives the evaluator missed (different registers: API reference, incident postmortem, tutorial). If "retire": argue for the rule — find AI prose only it catches, check nothing else covers it. Re-run vale yourself on your own scratch fixtures (repo root, scratch INI at MinAlertLevel=suggestion, delete after; never modify tracked files).\n\n${GOTCHAS}`,
      { label: `challenge:${rule}`, phase: 'Challenge', schema: CHALLENGE_SCHEMA, model: 'opus' }
    ).then(ch => ({ ...ev, challenged: true, challenge: ch }))
  }
)

const settled = results.filter(Boolean).map(r => ({
  ...r,
  final: r.challenged && r.challenge ? r.challenge.finalRecommendation : r.recommendation,
}))

// Barrier justified: the synthesis needs the full population to sanity-check style sizes.
const synthesis = await agent(
  `You are synthesizing the 2.0 graduation audit for ${REPO}. Per-rule verdicts (already adversarially
challenged where they moved rules in or out):\n\n${JSON.stringify(settled.map(({ rule, final, confidence, overlaps, migrationNotes }) => ({ rule, final, confidence, overlaps, migrationNotes })), null, 2)}\n\nProduce a markdown 2.0 Phase-0 report: (1) the three populations (promote/keep-metrics/retire) with one-line
rationale each; (2) sanity checks: does the metrics tier have a coherent identity and non-trivial population;
do the promotions create double-flags inside core or against write-good/proselint (list concrete merges
required, especially VocabularySwap vs OverusedVocabulary/FormalRegister); (3) the resulting Tengo rename
surface: which styles/config/scripts/*.tengo files belong to surviving rules and their proposed prefixed
names; (4) README/EXPERIMENTAL.md/packaging (release.yml) changes implied; (5) open questions for Tony.
Read the repo as needed to ground (3) and (4). Return the report as your final text.`,
  { label: 'synthesize', phase: 'Synthesize' }
)

return { verdicts: settled, report: synthesis }
