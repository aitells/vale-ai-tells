# Changelog

This file documents all major changes to this project.

The format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added

<!-- vale ai-tells.OverusedVocabulary = NO -->
<!-- vale ai-tells.EmDashUsage = NO -->
<!-- vale ai-tells.OpeningCliches = NO -->
<!-- vale ai-tells.VagueAttributions = NO -->
<!-- vale ai-tells.DespiteChallenges = NO -->
<!-- vale ai-tells.ServesAsDodge = NO -->
<!-- vale ai-tells.ParticipialPadding = NO -->
<!-- vale ai-tells.PromotionalPuffery = NO -->
<!-- vale ai-tells.FalseExclusivity = NO -->
<!-- vale ai-tells.NarrativePivots = NO -->
<!-- vale ai-tells.SequencingMarkers = NO -->
<!-- vale ai-tells.ContrastiveFormulas = NO -->
<!-- vale ai-tells.MicDrop = NO -->
<!-- vale ai-tells.RhetoricalSelfAnswer = NO -->
<!-- vale ai-tells.AICompoundPhrases = NO -->
<!-- vale Google.EmDash = NO -->
<!-- vale Google.LyHyphens = NO -->
<!-- vale proselint.CorporateSpeak = NO -->

- **VerbTricolon**: New rule detecting exactly-three parallel verb lists
  ("build, test, and deploy"), covering gerund, past tense, third person, modal,
  infinitive, colon-introduced, asyndetic, and subject-verb tricolon forms
- **VerbTricolonDensity**: New occurrence-based rule flagging paragraphs with
  multiple verb tricolons
- **MicDrop**: New rule catching short dramatic sentences used for manufactured
  emphasis in technical prose ("It matters." "Full stop." "And it shows.")
- **ServesAsDodge**: New rule detecting inflated copula replacements where AI
  substitutes "serves as a," "stands as the," "represents a pivotal," or
  "boasts a vibrant" for simple "is" or "are." Backed by PNAS data showing a
  10%+ decrease in is/are usage in AI text
- **ParticipialPadding**: New rule catching present participle (-ing) phrases
  appended for shallow analysis ("highlighting its importance," "reflecting
  broader trends," "solidifying its position"). The #1 discriminating feature
  in the PNAS study (GPT-4o uses participial clauses at 527% of the human rate)
- **VagueAttributions**: New rule flagging claims attributed to unnamed
  authorities ("experts argue," "studies show that," "research suggests,"
  "a growing body of evidence")
- **DespiteChallenges**: New rule catching the rigid "despite challenges"
  dismissal formula where AI acknowledges problems only to immediately dismiss
  them with optimism ("despite these challenges," "while challenges remain,"
  "challenges notwithstanding")
- **RhetoricalSelfAnswer**: New rule detecting self-posed rhetorical questions
  answered for dramatic effect ("The result/catch/worst part?" followed by an
  immediate answer)
- **SequencingMarkers**: New rule flagging formulaic ordinal sequencing that
  disguises a list as prose ("Firstly," "Secondly," "The first takeaway,"
  "The second benefit")
- **FalseExclusivity**: New rule catching false insider drama that claims
  something is secret or unspoken ("nobody talks about," "the dirty secret,"
  "what most people miss," "the elephant in the room")
- **NarrativePivots**: New rule detecting unearned dramatic pivot phrases
  ("something shifted," "everything changed," "that changed everything,"
  "it was a wake-up call," "the penny dropped")
- **PromotionalPuffery**: New rule flagging promotional and travel-brochure
  language ("nestled in," "vibrant community," "a beacon of," "renowned for
  its," "has emerged as a," "left an indelible mark")

### Changed

- **OverusedVocabulary**: Added 41 words from the PNAS study with 80-162x
  overuse rates: camaraderie (162x), palpable (145x), grapple (131x),
  fleeting (124x), ignite (122x), amidst (100x), unspoken (102x), solace,
  cacophony, bustling, gossamer, enigma, labyrinth, metropolis, expanse,
  indelible, kaleidoscopic, waft, beacon, intertwine, unravel, vibrant,
  and inflected forms
- **AICompoundPhrases**: Added "a cornerstone of," "the transformative power
  of," "deeply rooted," "the hallmark of"
- **ContrastiveFormulas**: Added "not only X but also Y" and "not because X,
  but because Y" causal variant patterns
- **OpeningCliches**: Added 13 patterns including "In a world where,"
  "As technology continues to evolve," "We live in an era," and variants
- **StackedAnaphora**: Expanded with two-item "No/Not" anaphora,
  comma-separated forms, and quantifier-word anaphora patterns
- **README**: Updated rule table to list all 41 rules; added "Known patterns
  not covered" subsection documenting 8 patterns that require analysis beyond
  Vale's capabilities; expanded Sources from 4 entries to 13 with structured
  bibliography (academic research, pattern catalogs, practitioner analysis)

<!-- vale ai-tells.OverusedVocabulary = YES -->
<!-- vale ai-tells.EmDashUsage = YES -->
<!-- vale ai-tells.OpeningCliches = YES -->
<!-- vale ai-tells.VagueAttributions = YES -->
<!-- vale ai-tells.DespiteChallenges = YES -->
<!-- vale ai-tells.ServesAsDodge = YES -->
<!-- vale ai-tells.ParticipialPadding = YES -->
<!-- vale ai-tells.PromotionalPuffery = YES -->
<!-- vale ai-tells.FalseExclusivity = YES -->
<!-- vale ai-tells.NarrativePivots = YES -->
<!-- vale ai-tells.SequencingMarkers = YES -->
<!-- vale ai-tells.ContrastiveFormulas = YES -->
<!-- vale ai-tells.MicDrop = YES -->
<!-- vale ai-tells.RhetoricalSelfAnswer = YES -->
<!-- vale ai-tells.AICompoundPhrases = YES -->
<!-- vale Google.EmDash = YES -->
<!-- vale Google.LyHyphens = YES -->
<!-- vale proselint.CorporateSpeak = YES -->

## [1.4.0] - 2026-02-17

### Added

- **UnpackExplore**: New rule flagging AI explainer announcements. AI's habit of
  announcing what it is about to explain rather than just explaining it: phrases
  starting with "Let me" or "Let us" followed by unpack, break down, dive into,
  walk through, dig into, examine, explore, and similar verbs
<!-- vale ai-tells.ListIntroductions = NO -->
- **ListIntroductions**: New rule catching AI list and summary announcements:
  "Below you'll find," "Here's a breakdown of," "Here's an overview of,"
  "Here is everything you need to know," "The following sections will," and
  variants
<!-- vale ai-tells.ListIntroductions = YES -->
<!-- vale ai-tells.AbsoluteAssertions = NO -->
- **AbsoluteAssertions**: New rule flagging AI overconfidence assertions:
  "the only way to," "the only real solution," "the single most important,"
  "make no mistake," "there is no denying," "above all else," and variants
<!-- vale ai-tells.AbsoluteAssertions = YES -->
<!-- vale ai-tells.StructureAnnouncements = NO -->
- **StructureAnnouncements**: New rule catching narrated structure and recap
  phrases: "key takeaway," "quick recap," "to recap," "a quick summary,"
  "to put it plainly," "to put this in perspective," and variants
<!-- vale ai-tells.StructureAnnouncements = YES -->

### Changed

<!-- vale ai-tells.OverusedVocabulary = NO -->
- **OverusedVocabulary**: Added salient, saliently, efficacy, paramount, adept,
  cognizant
<!-- vale ai-tells.OverusedVocabulary = YES -->
<!-- vale ai-tells.HedgingPhrases = NO -->
- **HedgingPhrases**: Added "as you might expect," "as you'd expect,"
  "as one might expect"
<!-- vale ai-tells.HedgingPhrases = YES -->
<!-- vale ai-tells.AbsoluteAssertions = NO -->
- **AffirmativeFormulas**: Removed "make no mistake" (now covered by
  AbsoluteAssertions)
<!-- vale ai-tells.AbsoluteAssertions = YES -->
- **Justfile**: Added `test-clean` (assert zero false positives),
  `scaffold` (create a new rule file from template), and `stats`
  (token counts per rule) recipes
- **README**: Added badge, "What to write instead" substitution table

## [1.3.0] - 2026-02-17

### Added

<!-- vale ai-tells.UrgencyInflation = NO -->
<!-- vale ai-tells.OverusedVocabulary = NO -->
<!-- vale ai-tells.OpeningCliches = NO -->
- **UrgencyInflation**: New rule catching false urgency and importance assertions:
  "cannot be overstated," "more important than ever," "has never been more
  critical," "the stakes have never been higher," "at a critical juncture,"
  "in an increasingly connected world," and variants
<!-- vale ai-tells.UrgencyInflation = YES -->
<!-- vale ai-tells.OverusedVocabulary = YES -->
<!-- vale ai-tells.OpeningCliches = YES -->

### Changed

<!-- vale ai-tells.AICompoundPhrases = NO -->
- **AICompoundPhrases**: Added "takes center stage," "paints a picture of,"
  "is not without its challenges," "whether we like it or not," and inflected forms
<!-- vale ai-tells.AICompoundPhrases = YES -->
<!-- vale ai-tells.HedgingPhrases = NO -->
- **HedgingPhrases**: Added "One thing is clear," "raises important questions,"
  "begs the question," "forces us to consider," "invites us to reflect,"
  "calls into question," "reminds us that," and related patterns
<!-- vale ai-tells.HedgingPhrases = YES -->

## [1.2.0] - 2026-02-17

### Added

<!-- vale ai-tells.OverusedVocabulary = NO -->
<!-- vale Google.EmDash = NO -->
<!-- vale ai-tells.EmDashUsage = NO -->
- **OverusedVocabularyVerbs**: New sequence-based rule constraining AI vocabulary
  tokens (leverage, navigate, showcase, harness, embark, foster, spearhead) to
  verb uses only — "financial leverage" and "climbing harness" no longer trigger
<!-- vale ai-tells.OverusedVocabulary = YES -->
<!-- vale Google.EmDash = YES -->
<!-- vale ai-tells.EmDashUsage = YES -->
- **AIAdjectiveNounPairs**: New sequence-based rule catching AI-characteristic
  adjectives immediately preceding any noun. Currently at `warning` level pending
  false positive calibration on real prose; will be promoted to `error` once
  the false positive rate is acceptable

### Changed

<!-- vale ai-tells.OverusedVocabulary = NO -->
<!-- vale Google.EmDash = NO -->
<!-- vale ai-tells.EmDashUsage = NO -->
- **OverusedVocabulary**: Removed leverage, navigate, showcase, harness, embark,
  foster, and spearhead (and inflected forms) — now handled with POS precision by
  OverusedVocabularyVerbs
<!-- vale ai-tells.OverusedVocabulary = YES -->
<!-- vale Google.EmDash = YES -->
<!-- vale ai-tells.EmDashUsage = YES -->
<!-- vale ai-tells.HedgingPhrases = NO -->
<!-- vale ai-tells.OverusedVocabulary = NO -->
- **HedgingPhrases**: Expanded with "It is essential/crucial/critical/necessary
  to [verb]" and "It is worth [verb]ing that" pattern families
<!-- vale ai-tells.HedgingPhrases = YES -->
<!-- vale ai-tells.OverusedVocabulary = YES -->
- **Rule files**: Added YAML document-start markers (`---`) to all rule files for yamllint strict-mode compliance

## [1.1.0] - 2026-02-17

### Added

- **Commit-message linting**: Vale now runs on `COMMIT_EDITMSG` via a
  `commit-msg` pre-commit hook, catching AI-generated patterns before they land
  in history. The hook applies only `ai-tells` rules (not Google/write-good/
  proselint) to keep noise low. See README for setup instructions.
- **Justfile**: Task runner with recipes for linting (`lint`, `lint-yaml`,
  `lint-prose`, `lint-markdown`, `lint-spelling`), Vale style syncing (`sync`),
  and pre-commit hook management (`prek`, `prek-all`, `prek-install`)
- **`.pre-commit-config.yaml`**: Pre-commit hooks for YAML validation
  (yamllint), spelling (codespell), Markdown linting (rumdl), and prose
  linting (vale), plus standard file hygiene hooks
- **`.yamllint.yaml`**: yamllint configuration extending default rules with
  `line-length` disabled (Vale rule files contain arbitrarily long regex tokens)
- **CLAUDE.md**: Development workflow instructions for first-time setup,
  running linters, and using pre-commit hooks

<!-- vale Google.EmDash = NO -->
<!-- vale ai-tells.EmDashUsage = NO -->
<!-- vale ai-tells.ClosingPleasantries = NO -->
<!-- vale ai-tells.RestatementMarkers = NO -->
<!-- vale ai-tells.SelfReference = NO -->
- **ClosingPleasantries**: New rule catching AI sign-off language — "I hope
  this helps," "Feel free to ask," "Don't hesitate to reach out," "Happy to
  help," "Best of luck," and similar pleasantries that appear at the end of
  AI-generated responses
- **RestatementMarkers**: New rule flagging redundant restatements — "In other
  words," "Simply put," "To be more specific," "What I mean is," etc.
- **SelfReference**: New rule detecting self-referential cross-references —
  "as mentioned above," "as noted earlier," "as we'll explore," "recall that," etc.
<!-- vale Google.EmDash = YES -->
<!-- vale ai-tells.EmDashUsage = YES -->
<!-- vale ai-tells.ClosingPleasantries = YES -->
<!-- vale ai-tells.RestatementMarkers = YES -->
<!-- vale ai-tells.SelfReference = YES -->

### Changed

<!-- vale ai-tells.OverusedVocabulary = NO -->
- **OverusedVocabulary**: Added comprehensive, innovative, notable,
  sophisticated, unprecedented, remarkable, exceptional, significant, profound,
  scalable, versatile, dynamic, crucial, vital, foundational, state-of-the-art,
  best-in-class, world-class, next-generation, next-level (and inflected forms)
<!-- vale ai-tells.OverusedVocabulary = YES -->
<!-- vale ai-tells.OpeningCliches = NO -->
- **OpeningCliches**: Added "Without further ado," "Gone are the days,"
  "Whether you're," "You might be wondering," "Chances are," "Look no further,"
  "You've come to the right place," "Ready to dive in," and variants
<!-- vale ai-tells.OpeningCliches = YES -->
<!-- vale ai-tells.FormalTransitions = NO -->
<!-- vale proselint.Cliches = NO -->
- **FormalTransitions**: Added "What's more," "Case in point," "Not to mention,"
  "Along the same lines," "In the same vein," "Better yet," "To top it off,"
  "On that note," "Given the above," "In light of this/that," "That is to say,"
  and more
<!-- vale ai-tells.FormalTransitions = YES -->
<!-- vale proselint.Cliches = YES -->
- **Metacommentary**: Expanded with more patterns
- **README**: Updated rule count to 22, refreshed rule table with all current
  rules, removed stale warning/suggestion level split (all rules are error level)
- **test-document.md**: Unwrapped hard-wrapped paragraphs; added test cases for
  all new and expanded rules

## [1.0.0] - 2026-02-01

### Changed

- **BREAKING**: All 19 rules now default to `error` level. Sorry not sorry.
  Override in your `.vale.ini` if this is too spicy for your workflow.
- Updated CLAUDE.md to reflect the all-errors policy and correct rule count (19)

## [0.6.0] - 2026-02-01

### Added

- **DefensiveHedges**: Catches preemptive qualifiers that soften claims before
  making them
- **EmphaticCopula**: Flags revelation patterns that announce insights instead
  of stating them
- **Metacommentary**: Detects self-referential narration about the text's own
  structure
- **OrganicConsequence**: Catches flowery cause-and-effect phrasing that makes
  designed choices sound inevitable
- **RhetoricalDevices**: Flags explicit labeling of rhetorical techniques
- **StackedAnaphora**: Catches repetitive sentence-starting patterns

### Changed

- Expanded ContrastiveFormulas with more patterns
- Added more filler phrases to FillerPhrases rule

## [0.5.0] - 2026-02-01

### Added

- Revelation patterns for "The [adjective] [noun] is/are" constructions

### Changed

- Updated AffirmativeFormulas with refined patterns

### Documentation

- Added CLAUDE.md instructions for preventing AI tells in AI-assisted writing
- Clarified that the package targets technical documentation

## [0.4.0] - 2025-12-02

### Changed

- Rewrote error messages to be immediately usable: each one explains why a
  pattern triggers and suggests alternatives.

## [0.3.0] - 2025-12-02

### Added

- **ContrastiveFormulas**: Detects hedging constructions that acknowledge
  limitations before shifting to positive claims
- **AffirmativeFormulas**: Catches emphatic assertions and certainty markers

### Documentation

- Added tone guidance embracing the irony of AI detecting AI

## [0.2.0] - 2025-12-02

### Fixed

- Em-dash detection rule now matches correctly

### Documentation

- Configured Vale with Google, write-good, and proselint styles for the repo
- Added acknowledgment that Claude wrote most of this codebase

## [0.1.0] - 2025-12-02

Initial release with 11 rules for detecting AI writing patterns.

### Rules (warning level)

<!-- vale off -->

- **OverusedVocabulary**: Words AI models use more frequently than human writers
  (for example: "delve", "crucial", "comprehensive", "robust", "nuanced")

<!-- vale on -->

- **OpeningCliches**: Stereotypical AI opening phrases
- **SycophancyMarkers**: Excessive agreement and validation phrases
- **AICompoundPhrases**: Compound constructions favored by AI models

### Rules (suggestion level)

- **HedgingPhrases**: Qualification language that softens claims
- **ConclusionMarkers**: Formulaic conclusion transitions
- **FormalTransitions**: Overly formal transition phrases
- **FalseBalance**: Constructions that present artificial balance
- **EmDashUsage**: Frequent em-dash usage (a stylistic tell)
- **FillerPhrases**: Padding language that adds no meaning
- **FormalRegister**: Unnecessarily formal vocabulary choices

[1.4.0]: https://github.com/tbhb/vale-ai-tells/compare/v1.3.0...v1.4.0
[1.3.0]: https://github.com/tbhb/vale-ai-tells/compare/v1.2.0...v1.3.0
[1.2.0]: https://github.com/tbhb/vale-ai-tells/compare/v1.1.0...v1.2.0
[1.1.0]: https://github.com/tbhb/vale-ai-tells/compare/v1.0.0...v1.1.0
[1.0.0]: https://github.com/tbhb/vale-ai-tells/compare/v0.6.0...v1.0.0
[0.6.0]: https://github.com/tbhb/vale-ai-tells/compare/v0.5.0...v0.6.0
[0.5.0]: https://github.com/tbhb/vale-ai-tells/compare/v0.4.0...v0.5.0
[0.4.0]: https://github.com/tbhb/vale-ai-tells/compare/v0.3.0...v0.4.0
[0.3.0]: https://github.com/tbhb/vale-ai-tells/compare/v0.2.0...v0.3.0
[0.2.0]: https://github.com/tbhb/vale-ai-tells/compare/v0.1.0...v0.2.0
[0.1.0]: https://github.com/tbhb/vale-ai-tells/releases/tag/v0.1.0
