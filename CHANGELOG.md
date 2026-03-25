# Changelog

This file documents all major changes to this project.

The format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

<!-- vale off -->

### Added

- **AnthropomorphicJustification**: New rule for treating abstractions like
  employees under performance review: "earns its keep," "does the heavy
  lifting," "pulls its weight," "pays for itself," "speaks for itself," etc.
- **ParallelStaccato**: New rule for back-to-back minimal sentences with
  parallel structure ("Engineers build. Managers ship.") and solo two-word
  staccato sentences ("Complexity scales.").
- **MicDropHeadings**: New rule (scoped to headings) for tagline-style headings:
  "Clarity, not cleverness," "Simple, then fast," "Speed over correctness,"
  "X first, Y second," etc.

### Changed

- **ContrastiveFormulas**: Added plural subject negation-correction patterns
  ("These aren't X. They're Y."), "doesn't mean X / it means Y" patterns, and
  multi-word subject patterns ("The colophon isn't a disclaimer. It's a
  feature.") that the existing single-word subject rules didn't cover.
- **MicDrop**: Added contrastive fragments ("Dense, not cramped."), preference
  fragments ("Clarity over cleverness."), sequencing fragments ("Scannable,
  then readable."), imperative mic-drops ("Trust the process."), categorical
  declarations ("Density is a feature."), and colon-tagged tagline glosses
  (": the reference shelf, not the opinion column.").

<!-- vale on -->

## [1.6.2] - 2026-03-22

### Fixed

- **Vocabulary**: Renamed project vocabulary from `ai-tells` to `vale-ai-tells`
  to avoid confusion with the style package, and excluded it from release zips
  since it is a project-local spelling allowlist, not something consumers need.
- **Tengo scripts**: Strip HTML comments from prose analysis so vale
  suppression directives (`<!-- vale ... -->`) are not treated as content.
  Also filter list items and table rows from SentenceStartRepetition to
  prevent structured lists from triggering false positives.

## [1.6.1] - 2026-03-20

### Fixed

- **Packaging**: `ai-tells-experimental.zip` now uses Vale's nested package
  structure (`ai-tells-experimental/styles/...`) so that `vale sync` correctly
  installs both rules and Tengo scripts. The old zip had `config/scripts/` as a
  sibling directory, and Vale's package sync silently dropped it.

## [1.6.0] - 2026-03-20

### Added

<!-- vale off -->
- **ai-tells-experimental**: New opt-in style with 13 rules for detecting
  structural AI writing patterns beyond Vale's regular expression rules.
  Uses Tengo scripts, metric formulas, capitalization, and substitution
  check types to analyze document-level properties. Shipped as a separate
  `ai-tells-experimental.zip` release artifact (includes `config/scripts/`).
  All rules at `warning` level; thresholds are research-grounded starting
  points pending calibration on a larger corpus.
- **SentenceLengthVariance** (script): Flags sections where the coefficient
  of variation of sentence word counts falls below 0.30. Gibbs (2024):
  ChatGPT averages ~27 words/sentence with low variance; PNAS (2025):
  instruction-tuned LLMs compress the sentence-length range humans produce
- **ParagraphLengthVariance** (script): Flags sections where paragraph-length
  CV falls below 0.25. Pangram Labs (2025): AI paragraphs default to uniform
  60-100 word blocks
- **SentenceStartRepetition** (script): Flags sections where >30% of
  sentences start with the same word (at least 6 sentences, 3 occurrences).
  Complements `StackedAnaphora` for non-consecutive repetition
- **SentenceStartEntropy** (script): Measures Shannon entropy of sentence-
  starting words per section. Flags when normalized entropy falls below 0.65,
  catching low diversity even when no single opener dominates
- **ContentDuplication** (script): Detects near-identical paragraphs within
  a section using Jaccard word-overlap similarity. Flags the later occurrence
  when two paragraphs share more than 60% of their words
- **ContractionAvoidance** (script): Detects documents that avoid
  contractions despite using informal language. Two-pass approach: informality
  gate (pronouns, questions) then ratio check. PNAS (2025): GPT models use
  contractions at 60-63% of the human rate
- **TransitionRepetition** (script): Flags when the same formal transition
  phrase appears 3+ times within a section. Tracks 20 common transitions
  including "moreover," "furthermore," "additionally," "hence," "thus"
- **TricolonDensityDocument** (script): Detects when tricolons make up >60%
  of all enumerated lists in a document with at least 4 tricolons and 20%
  sentence density. Gorrie (2024), tropes.fyi: tricolon overuse is a key AI
  rhetorical tell
- **AverageSentenceLength** (metric): Flags documents where
  `words / sentences > 25.0`
- **LongWordDensity** (metric): Flags documents where
  `long_words / words > 0.4`. PNAS (2025): mean word length ranks as a top-5
  discriminating feature between AI and human text
- **ComplexWordDensity** (metric): Flags documents where
  `complex_words / words > 0.3`. PNAS (2025): nominalizations appear at
  150-214% of human rates in GPT output
- **HeadingTitleCase** (capitalization): Flags markdown headings using Title
  Case. Wikipedia: "AI chatbots strongly tend to capitalize all main words
  in section headings." Supports project-specific exceptions via Vale vocab
- **VocabularySwap** (substitution): Inline rewrite suggestions for 20 AI
  vocabulary words (56 swap entries covering inflected forms). Complements
  `OverusedVocabulary` by suggesting concrete alternatives
<!-- vale on -->

### Changed

- **Release workflow**: `ai-tells-experimental.zip` now ships as its own
  release artifact alongside `ai-tells.zip` and `ai-tells-commits.zip`

### Fixed

- **SentenceStartRepetition**: Fixed integer division that caused the rule
  to fire only at 100% repetition instead of the intended 30% threshold
- **ContractionAvoidance**: Fixed integer division that caused false
  positives on every document with full forms regardless of contraction count.
<!-- vale Google.We = NO -->
<!-- vale write-good.E-Prime = NO -->
  Added 9 missing contraction/full-form pairs (you'll, you've, she's, he's,
  there's, here's, what's, who's, let's)
<!-- vale write-good.E-Prime = YES -->
<!-- vale Google.We = YES -->
<!-- vale ai-tells.FormalTransitions = NO -->
<!-- vale Google.Quotes = NO -->
- **TransitionRepetition**: Fixed substring matching that counted "thus"
  inside "enthusiasm" and "hence" inside "whence". Now uses word-boundary
  matching
<!-- vale ai-tells.FormalTransitions = YES -->
<!-- vale Google.Quotes = YES -->
- **SentenceLengthVariance**, **SentenceStartRepetition**: Fixed section
  variable overwriting that broke position lookups (all matches pointed to
  position 0)
- **ParagraphLengthVariance**: Fixed code-block toggle tracking that got
  permanently stuck, skipping all content after the first fenced block.
  Now strips code blocks via pattern matching before paragraph splitting
- **Script rule messages**: Removed `%s` placeholders from 4 script rule
  messages that dumped the entire matched text span instead of metric values
- **Section splitting**: All 7 section-splitting scripts now handle headings
  at the start of a document; earlier versions needed a leading newline

## [1.5.1] - 2026-03-20

### Fixed

- **Packaging**: `ai-tells-commits` now ships as its own zip asset,
  `ai-tells-commits.zip`, so Vale can install it as a separate package.
  Before, it shipped inside `ai-tells.zip`, which Vale ignored during
  sync because the directory name didn't match the package name.

## [1.5.0] - 2026-03-20

### Added

<!-- vale off -->

- **VerbTricolon**: New rule detecting exactly-three parallel verb lists
  ("build, test, and deploy"), covering gerund, past tense, third person, modal,
  infinitive, colon-introduced, asyndetic, and subject-verb tricolon forms
- **VerbTricolonDensity**: New occurrence-based rule flagging paragraphs with
  two or more verb tricolons
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

<!-- vale on -->

<!-- vale off -->
- **ai-tells-commits**: New opt-in style with 6 rules purpose-built for
  detecting AI tells in commit messages and PR descriptions. Shipped in the
  same release zip as `ai-tells` but in a separate `ai-tells-commits` directory
  so users can enable it independently via `BasedOnStyles = ai-tells-commits`.
  Rules based on research including "Fingerprinting AI Coding Agents on GitHub"
  (arXiv:2601.17406), the Allstacks Emoji Commit Index, and community analysis
  of output from Claude Code, Copilot, Cursor, Aider, and Windsurf.
- **CommitSelfReference**: Flags self-narrating preambles: "This commit adds,"
  "This PR introduces," "In this change," "These changes ensure," etc.
- **CommitTrailingJustification**: Flags trailing clauses that restate the
  obvious: "ensuring consistency," "improving readability," "which allows for,"
  "for better maintainability," etc.
- **CommitBuzzwords**: Flags vague adjective+noun combos characteristic of AI
  commits: "comprehensive tests," "robust error handling," "proper validation,"
  "various fixes," "relevant components," "necessary changes," etc.
- **CommitHedging**: Flags inappropriate uncertainty for changes already made:
  "This should fix," "This may help," "seems to resolve," etc.
- **CommitEmoji**: Flags systematic gitmoji prefixes. Emoji commit adoption
  jumped from ~25% to ~75% of organizations in 2023–2025, driven almost
  entirely by AI commit tools.
- **CommitOverexplanation**: Flags commit-specific filler: "As part of this
  change," "The purpose of this commit," "Summary of changes," "The following
  changes were made," etc.
<!-- vale on -->

### Changed

<!-- vale off -->
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
<!-- vale on -->
- **StackedAnaphora**: Expanded with two-item "No/Not" anaphora,
  comma-separated forms, and quantifier-word anaphora patterns
- **README**: Updated rule table to list all 41 rules; added "Known patterns
  not covered" subsection documenting 8 patterns that require analysis beyond
  Vale's capabilities; expanded Sources from 4 entries to 13 with structured
  bibliography covering academic research, pattern catalogs, and practitioner analysis
- **Release workflow**: `ai-tells.zip` now includes both `ai-tells/` and
  `ai-tells-commits/` directories
- **.vale.ini**: `COMMIT_EDITMSG` section now uses both `ai-tells` and
  `ai-tells-commits` styles
- **Justfile**: `stats` recipe now reports token counts for both styles
- **test-commit-messages.md**: New test document with examples of all 6
  commit message AI tells

## [1.4.0] - 2026-02-17

### Added

<!-- vale off -->
- **UnpackExplore**: New rule flagging AI explainer announcements. AI's habit of
  announcing what it is about to explain rather than just explaining it: phrases
  starting with "Let me" or "Let us" followed by unpack, break down, dive into,
  walk through, dig into, examine, explore, and similar verbs
<!-- vale on -->
<!-- vale off -->
- **ListIntroductions**: New rule catching AI list and summary announcements:
  "Below you'll find," "Here's a breakdown of," "Here's an overview of,"
  "Here is everything you need to know," "The following sections will," and
  variants
<!-- vale on -->
<!-- vale off -->
- **AbsoluteAssertions**: New rule flagging AI overconfidence assertions:
  "the only way to," "the only real solution," "the single most important,"
  "make no mistake," "there is no denying," "above all else," and variants
<!-- vale on -->
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

<!-- vale off -->
- **UrgencyInflation**: New rule catching false urgency and importance assertions:
  "cannot be overstated," "more important than ever," "has never been more
  critical," "the stakes have never been higher," "at a critical juncture,"
  "in an increasingly connected world," and variants
<!-- vale on -->

### Changed

<!-- vale off -->
- **AICompoundPhrases**: Added "takes center stage," "paints a picture of,"
  "is not without its challenges," "whether we like it or not," and inflected forms
<!-- vale on -->
<!-- vale off -->
- **HedgingPhrases**: Added "One thing is clear," "raises important questions,"
  "begs the question," "forces us to consider," "invites us to reflect,"
  "calls into question," "reminds us that," and related patterns
<!-- vale on -->

## [1.2.0] - 2026-02-17

### Added

<!-- vale off -->
- **OverusedVocabularyVerbs**: New sequence-based rule constraining AI vocabulary
  tokens (leverage, navigate, showcase, harness, embark, foster, spearhead) to
  verb uses only — "financial leverage" and "climbing harness" no longer trigger
<!-- vale on -->
- **AIAdjectiveNounPairs**: New sequence-based rule catching AI-characteristic
  adjectives immediately preceding any noun. Currently at `warning` level pending
  false positive calibration on real prose. Promotion to `error` follows once
  the false positive rate drops enough

### Changed

<!-- vale off -->
- **OverusedVocabulary**: Removed leverage, navigate, showcase, harness, embark,
  foster, and spearhead plus inflected forms — now handled with POS precision by
  OverusedVocabularyVerbs
<!-- vale on -->
<!-- vale off -->
- **HedgingPhrases**: Expanded with "It is essential/crucial/critical/necessary
  to [verb]" and "It is worth [verb]ing that" pattern families
<!-- vale on -->
<!-- vale Google.Parens = NO -->
- **Rule files**: Added YAML document-start markers (`---`) to all rule files for yamllint strict-mode compliance
<!-- vale Google.Parens = YES -->

## [1.1.0] - 2026-02-17

### Added

<!-- vale off -->
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
  `line-length` turned off (Vale rule files contain arbitrarily long regular expression tokens)
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
<!-- vale on -->

### Changed

<!-- vale off -->
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
<!-- vale on -->
- **Metacommentary**: Expanded with more patterns
- **README**: Updated rule count to 22, refreshed rule table with all current
  rules, removed stale warning/suggestion level split since all rules now use error level
- **test-document.md**: Unwrapped hard-wrapped paragraphs; added test cases for
  all new and expanded rules

## [1.0.0] - 2026-02-01

### Changed

- **BREAKING**: All 19 rules now default to `error` level. Sorry not sorry.
  Override in your `.vale.ini` if that feels too spicy for your workflow.
- Updated CLAUDE.md to reflect the all-errors policy and correct rule count of 19

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

<!-- vale write-good.E-Prime = NO -->
- Revelation patterns for "The [adjective] [noun] is/are" constructions
<!-- vale write-good.E-Prime = YES -->

### Changed

- Updated AffirmativeFormulas with refined patterns

### Documentation

- Added CLAUDE.md instructions for preventing AI tells in AI-assisted writing
- Clarified that the package targets technical documentation

## [0.4.0] - 2025-12-02

### Changed

- Rewrote error messages for immediate usability: each one explains why a
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

### Rules at warning level

<!-- vale off -->

- **OverusedVocabulary**: Words AI models use more frequently than human writers
  (for example: "delve", "crucial", "comprehensive", "robust", "nuanced")

<!-- vale on -->

- **OpeningCliches**: Stereotypical AI opening phrases
- **SycophancyMarkers**: Excessive agreement and validation phrases
- **AICompoundPhrases**: Compound constructions favored by AI models

### Rules at suggestion level

- **HedgingPhrases**: Qualification language that softens claims
- **ConclusionMarkers**: Formulaic conclusion transitions
- **FormalTransitions**: Overly formal transition phrases
- **FalseBalance**: Constructions that present artificial balance
- **EmDashUsage**: Frequent em-dash usage, a stylistic tell
- **FillerPhrases**: Padding language that adds no meaning
- **FormalRegister**: Unnecessarily formal vocabulary choices

[1.6.2]: https://github.com/tbhb/vale-ai-tells/compare/v1.6.1...v1.6.2
[1.6.1]: https://github.com/tbhb/vale-ai-tells/compare/v1.6.0...v1.6.1
[1.6.0]: https://github.com/tbhb/vale-ai-tells/compare/v1.5.1...v1.6.0
[1.5.1]: https://github.com/tbhb/vale-ai-tells/compare/v1.5.0...v1.5.1
[1.5.0]: https://github.com/tbhb/vale-ai-tells/compare/v1.4.0...v1.5.0
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
