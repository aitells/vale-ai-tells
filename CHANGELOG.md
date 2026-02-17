# Changelog

This file documents all notable changes to this project.

The format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added

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

- **ClosingPleasantries**: New rule catching AI sign-off language — "I hope
  this helps," "Feel free to ask," "Don't hesitate to reach out," "Happy to
  help," "Best of luck," and similar pleasantries that appear at the end of
  AI-generated responses
- **RestatementMarkers**: New rule flagging redundant restatements — "In other
  words," "Simply put," "To be more specific," "What I mean is," etc.
- **SelfReference**: New rule detecting self-referential cross-references —
  "as mentioned above," "as noted earlier," "as we'll explore," "recall that," etc.

### Changed

- **OverusedVocabulary**: Added comprehensive, innovative, notable,
  sophisticated, unprecedented, remarkable, exceptional, significant, profound,
  scalable, versatile, dynamic, crucial, vital, foundational, state-of-the-art,
  best-in-class, world-class, next-generation, next-level (and inflected forms)
- **OpeningCliches**: Added "Without further ado," "Gone are the days,"
  "Whether you're," "You might be wondering," "Chances are," "Look no further,"
  "You've come to the right place," "Ready to dive in," and variants
- **FormalTransitions**: Added "What's more," "Case in point," "Not to mention,"
  "Along the same lines," "In the same vein," "Better yet," "To top it off,"
  "On that note," "Given the above," "In light of this/that," "That is to say,"
  and more
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

- Rewrote error messages to be actionable for AI agents. Messages now explain
  why a pattern triggers and suggest alternatives.

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

[1.0.0]: https://github.com/tbhb/vale-ai-tells/compare/v0.6.0...v1.0.0
[0.6.0]: https://github.com/tbhb/vale-ai-tells/compare/v0.5.0...v0.6.0
[0.5.0]: https://github.com/tbhb/vale-ai-tells/compare/v0.4.0...v0.5.0
[0.4.0]: https://github.com/tbhb/vale-ai-tells/compare/v0.3.0...v0.4.0
[0.3.0]: https://github.com/tbhb/vale-ai-tells/compare/v0.2.0...v0.3.0
[0.2.0]: https://github.com/tbhb/vale-ai-tells/compare/v0.1.0...v0.2.0
[0.1.0]: https://github.com/tbhb/vale-ai-tells/releases/tag/v0.1.0
