# Todo

## Investigate Vale sequence extension

Vale's `sequence` extension adds sentence-level NLP with part-of-speech tagging.
All ai-tells rules currently use `existence` (pattern matching only).

Investigate whether any rules could benefit from `sequence`:

- [x] Review which patterns could use POS awareness for better precision
- [x] Test `sequence` performance impact vs `existence`
- [x] Identify false positive reduction opportunities

See: <https://vale.sh/docs/checks/sequence>

### Findings (branch: vale-sequence)

Three prototype rules now live in `styles/ai-tells/`:

<!-- vale ai-tells.EmDashUsage = NO -->
<!-- vale ai-tells.OverusedVocabulary = NO -->
<!-- vale ai-tells.AIAdjectiveNounPairs = NO -->
<!-- vale ai-tells.PassiveMetacommentary = NO -->
<!-- vale ai-tells.FormalTransitions = NO -->
**`OverusedVocabularyVerbs.yml`** - Constrains ambiguous tokens (`leverage`,
`navigate`, `showcase`, `harness`, `embark`, `foster`, `spearhead`) to verb
POS tags only. Corresponding noun forms removed from `OverusedVocabulary.yml`.
Testing confirms zero false positives on noun uses such as "financial leverage
ratio" and "climbing harness."

**`AIAdjectiveNounPairs.yml`** - Catches AI-characteristic adjectives
immediately preceding any noun, such as "holistic approach," "seamless
integration," and "transformative impact." Set at `warning` level pending false
positive calibration.

**`PassiveMetacommentary.yml`** - Matches `it + modal/be + adj + to/that`
grammar to catch "It is important to," "It is essential to," and similar
constructions without requiring enumeration. Known limitation: cannot
distinguish AI throat-clearing from genuine requirements (such as testing a
security check before deploying). False positives confirmed in
`test-false-positives.md`. May need narrowing to `adj + to` patterns only, or
downgrading to `warning`.
<!-- vale ai-tells.EmDashUsage = YES -->
<!-- vale ai-tells.OverusedVocabulary = YES -->
<!-- vale ai-tells.AIAdjectiveNounPairs = YES -->
<!-- vale ai-tells.PassiveMetacommentary = YES -->
<!-- vale ai-tells.FormalTransitions = YES -->

**Performance** (7,060-word corpus): existence-only runs in 1.07 seconds;
adding three sequence rules takes 1.43 seconds. Overhead is approximately
360 milliseconds, within the 500 millisecond CI threshold.

**yamllint note:** Existing rule files lack `---` document start markers and
fail `yamllint --strict`. New sequence rule files include `---`. A follow-up
should add `---` to all existing rule files or disable `document-start` in the
config.

### Next steps

- [ ] Collect false positive data on real prose for `AIAdjectiveNounPairs`
      and promote from `warning` to `error` once the false positive rate is
      acceptable
- [ ] Decide whether to merge `PassiveMetacommentary` as `warning` or refine
      the pattern to reduce false positives on genuine requirement statements
- [ ] Fix the `yamllint` `document-start` issue across all existing rule files
      or update the config
- [ ] Merge the `vale-sequence` branch if the prototypes get approved
