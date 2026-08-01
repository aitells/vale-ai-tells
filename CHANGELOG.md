# Changelog

This file documents all major changes to this project.

The format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

<!-- vale off -->

### Fixed

- **ColloquialAssessments**, **DefensiveHedges**, **Metacommentary**,
  **MicDrop**, **MicDropHeadings**, **ParallelStaccato**,
  **RhetoricalDevices**, **RhetoricalSelfAnswer**, **StackedAnaphora**:
  Anchor the tokens at word boundaries. These rules set `nonword: true`,
  which drops the boundaries Vale adds by default on both ends, so 280
  tokens could start matching inside a word and 42 could match the front
  of a longer one. An audit of every rule carrying that setting found
  these nine. ColloquialAssessments was reachable from ordinary prose
  because it also folds case, and a word such as "blithe" ends with the
  article the token starts with. The rest needed a capital letter inside
  a word, which happens when a camel case identifier appears in a
  sentence. MicDropHeadings also matched the front of a longer adverb, so
  a heading that ended in "secondly" tripped the token ending in
  "second". Alerts on the fixtures and across the consumer repositories
  are unchanged.

<!-- vale on -->

## [1.27.1] - 2026-07-31

<!-- vale off -->

### Fixed

- **ContractionAvoidance**: Count contractions written with the typographic
  apostrophe (U+2019). Every pattern in the script used the straight
  apostrophe, so a document that went through a typographer counted as
  having no contractions at all and tripped the rule regardless of how it
  was written. The script now normalizes the apostrophe before counting.
- **VerbTricolon**: Anchor every token that begins with a word character at
  a word boundary. The rule sets `nonword: true`, which suppresses the
  boundaries Vale adds by default, so a token that leads with a literal
  word matched inside longer words. Prose naming an identifier that ends
  in "can" tripped the modal token, and words such as "into" and "bayou"
  tripped the infinitive and pronoun tokens. Tokens that lead with `\w+`
  never had the problem, because a match found inside a word is also found
  from the word start, so `VerbTricolonDensity` needed no change. This
  narrows the rule and drops false positives only. Alerts on the test
  fixtures are unchanged.

<!-- vale on -->

## [1.27.0] - 2026-07-31

<!-- vale off -->

### Changed

- **EmphaticCopula**: Add six italicized intensifiers (actually, really,
  never, always, truly, literally) in both the asterisk and the underscore
  form, so the rule covers stress italics alongside the copula pattern it
  started with. The message now says "common word" instead of "copula",
  which the determiner and conjunction tokens had already outgrown. Vale
  3.17 added an `emphasis` scope that reads these spans without markup
  patterns, but that scope aborts the whole style on older Vale, so the
  rule stays on `scope: raw` until a dedicated inline-scope package lands.

<!-- vale on -->

## [1.26.0] - 2026-07-27

<!-- vale off -->

### Added

- **DoubleHyphen**: New rule. Splits the literal double-hyphen token out
  of `EmDashUsage` into a dedicated rule whose message gives the two real
  fixes: backtick it when it is a CLI flag or literal, or use a real em
  dash character when it is punctuation. `EmDashUsage` keeps the true em
  dash tokens and its own message. Brings the main-style rule count to 77.
- **Fixture CI gate**: New `just test` recipe suite and a `lint.yml` step
  that run `test-document.md` and `test-commit-messages.md` through
  `.vale-test.ini` and assert both fire a healthy volume of errors, while
  `test-false-positives.md` stays clean. Adds a `CommitPastTense` smoke
  test that feeds single subject lines through Vale, since the rule's raw
  anchor only sees line 1 and the corpus fixture cannot exercise it.
  Positive fixtures were also added for the 14 main rules that never fired
  on `test-document.md`.

### Changed

- **AIAdjectiveNounPairs**, **CommitFileListing**,
  **CommitUnquantifiedClaims**: Promoted from `warning` to `error`, so the
  package's "all rules default to error" claim now holds across every
  style. `AIAdjectiveNounPairs` also gains `ignorecase` to match its
  sibling sequence rules.
- **OverusedVocabulary**: Reframed as the miscellaneous vocabulary bucket.
  Removed the nine words a more specific rule already owns (cornerstone,
  pivotal, nascent, testament, tapestry, multifaceted, intricate, seamless,
  transformative) so one span raises one alert; `nascent` now belongs to
  `GrowthMetaphors`. A header comment records the bucket principle. Inflected
  forms no sibling rule catches (the adverb, the plural) stay.
- **FormalRegister**: Add `ignorecase` so sentence-initial imperatives
  ("Utilize the helper.") no longer escape, and stop flagging `framework`
  and `methodology`, precise technical nouns the suggested swaps cannot
  replace.
- **FormalTransitions**: Anchor the pure-adverb tokens (Significantly,
  Fundamentally, Specifically, Essentially) to sentence-initial position
  so mid-sentence degree adverbs ("runs significantly faster") stay clean.
- **Cross-rule ownership**: Gave each shared phrase family one owner to end
  duplicate alerts. `UnpackExplore` owns "Let's explore/unpack/dive into"
  (dropped from `Metacommentary`); `StructureAnnouncements` owns "the
  takeaway is" (dropped from `Metacommentary` and `AffirmativeFormulas`);
  `HedgingPhrases` owns "it's worth noting/mentioning" (dropped from
  `Metacommentary`); `ContrastiveNegation` owns the two-item "no X, no Y"
  (dropped from `StackedAnaphora`, which keeps the three-plus shape);
  `MicDrop` owns pronoun one-liners like "It works." (excluded from
  `ParallelStaccato`); `ConclusionMarkers` owns "the bottom line is"
  (dropped from `AffirmativeFormulas`); `DefensiveHedges` owns the "to be
  honest, X, but Y" shape (narrowed in `FillerPhrases`).
- **AnthropomorphicJustification**: Add "paying for itself" and "paying
  dividends" to the paying family, matching the fuller weight family.
- **FigurativeStrikes**, **FigurativeRides**: Extend the verb stems to the
  base forms ("strike a chord," "ride on this assumption"), which the
  inflected-only stems missed.
- **ParallelStaccato**: Fix the solo-verb token so "push" matches, not
  only "pushes."
- **VerbTricolon**: Add lowercase pronoun subjects so mid-sentence "they
  process X, validate Y, and format Z" is covered, matching the lowercase
  modal arm.
- **VocabularySwap** (experimental): Add the missing past-tense swap keys
  (facilitated, bolstered, elucidated, reimagined, encompassed, endeavored
  and endeavoured). The keys whose past tense doubles as a technical
  adjective (streamlined, elevated) stay omitted with a comment. The rule
  is now documented as an alternative to, not an addition on top of, the
  core vocabulary rules.

### Fixed

- **ConclusionMarkers**: Anchor the bare "Overall" and "Ultimately" to
  sentence-initial discourse-marker position so the ordinary adverb senses
  ("the overall design," "ultimately depends on") stay clean.
- **MicDrop**: Restrict the "Period." token to the standalone emphatic
  sentence so a noun ending ("billing period.") no longer fires.
- **StrategyBuzzwords**: Stop the "moat around" arm from matching the
  literal castle sense the file's own header promises stays clean.
- **FalseBalance**: Drop the "-dependent" compounds (context-dependent,
  situation-dependent), precise technical vocabulary with no evasive
  reading; the dodge "varies depending on" stays.
- **CommitTestEnumeration**: Require the comma-separated pass and fail pair
  so "retry 3 failed uploads" no longer trips the rule.
- **CommitMarketingAdjectives**: Drop "first-class" and "first class,"
  which match standard computer-science terminology.
- **CommitHedging**: Drop bare "seems to be," which fires on diagnostic
  prose ("the root cause seems to be a race condition").
- **Dead tokens**: Remove entries that never matched or duplicated a
  sibling: the duplicate "To put it another way" in `RestatementMarkers`,
  the duplicate emoji in `CommitEmoji`, and the shadowed "natural beauty
  of" and "an enduring legacy" in `PromotionalPuffery`.

<!-- vale on -->

## [1.25.0] - 2026-07-17

<!-- vale off -->

### Added

- **FigurativeLoud**: New rule. The mirror of FigurativeQuiet: "loud"
  for personified emphasis. A check that "fails loudly," a linter that
  "loudly complains," a metric that "sends a loud signal," a warning
  that comes through "loud and clear." Gated on the construction, so
  literal loudness (a room, music, a noise) and bare "out loud"
  (reading, thinking) never match.
- **FigurativeQuiet**: New rule. Flags "quiet" for personified
  inaction: a check that "stays quiet," a log that "goes quiet," a
  handler that "quietly drops" the error, "quietly ships," "quietly
  falls back." Gated on the construction (an inanimate subject going
  silent, or "quietly" ahead of an action verb), so literal quiet (a
  room, a person, the quiet flag) never matches. Named for the tell
  this package's own prose leaned on all session.
- **FigurativeWins**: New rule. Flags "wins" framing a choice as a
  contest: an approach that "wins the day," a design that "wins out," a
  refactor that is "a quick win," "a winning combination," "for the
  win." Complement-gated in the FigurativeSits mold, so the precedence
  sense ("last write wins," "the more specific rule wins") and literal
  winning (a team, a game) stay quiet.

### Changed

- **FigurativeCarries**: Add the content-possession shape, where an
  inanimate component is treated as a vessel that hauls abstract cargo
  rather than one that contains or transmits it ("the daemon carries no
  pipeline logic," "the packet carries the payload," "the signal
  carries data"). Gated on code-structure and transport nouns, so
  literal physical carrying and the phrasal "carries out" (execute)
  stay quiet. The message now names containment as well as consequence.
- **FigurativeRides**: Add the vehicle-exploitation shape, where an
  operation is dressed as a passenger on the infrastructure it merely
  uses ("the query rides the index," "the lookup rides the cache," "the
  scan rides the hot path"). Gated on a curated software-mechanism noun
  set, so a literal "rides the bus" stays quiet.
- **AnthropomorphicJustification**: Add the reflexive-agency shape,
  where an operation performs a deliberate act on itself ("the query
  narrows itself," "the config tunes itself," "the rule set prunes
  itself"). Self-healing and self-correcting adjective forms stay quiet.

<!-- vale on -->

## [1.24.0] - 2026-07-13

<!-- vale off -->

### Added

- **HollowAcknowledgment**: New rule. Flags the staged-insight
  antithesis that names a thing and then declines to act on it: "names
  the gap without filling it," "identifies the problem without solving
  it," "raises the question without answering it," plus the shorthand
  "all analysis, no action." Gated on a notice-verb, a "without"
  gerund, and a back-referring pronoun, so a plain "left without saying
  goodbye" stays quiet.
- **FigurativeStrikes**: New rule. Flags "strikes" for resonance and
  aptness: an argument that "strikes a chord," a critique that "strikes
  at the core of" the design, a phrase that "strikes the right tone,"
  "struck gold." Complement-gated in the FigurativeSits mold, so
  literal striking (a match, lightning, a labor strike) stays quiet;
  "strike a balance" remains in FalseBalance and "at the heart of"
  remains in PromotionalPuffery.
- **FigurativeLends**: New rule. Flags "lends" for conferring an
  abstract quality: a structure that "lends itself to" reuse, a study
  that "lends credence," a detail that "lends weight." Complement-gated,
  so literal lending (money, a book) stays quiet.
- **FigurativeDraws**: New rule. Flags "draws" for sourcing and
  comparison: an argument that "draws on" prior work, a section that
  "draws a distinction," a heading that "draws attention to" a caveat,
  a post that "draws to a close." Complement-gated, so literal drawing
  (a card, water, a weapon, blood) stays quiet.
- **FigurativeCasts**: New rule. Flags "casts" for projecting an
  abstraction: a finding that "casts doubt on" a result, a decision
  that "casts a long shadow," a rewrite that "casts a wide net."
  Complement-gated, so literal casting (a fishing line, metal, a vote,
  actors) stays quiet.
- **FigurativeFalls**: New rule. Flags "falls" for shortcoming,
  membership, and neglect: a result that "falls short," a design that
  "falls apart," a case that "falls under" a category or "falls within
  scope," a task that "falls by the wayside" or "through the cracks," a
  request that "falls on deaf ears," responsibility that "falls to" a
  team. Complement-gated in the FigurativeSits mold, so literal falling
  (prices, temperature, night, rain) stays quiet; disable the rule for
  gravity or weather writing. The past-tense "things fell into place"
  remains in NarrativePivots, and "falls into three categories" remains
  in CataphoricForecasting.

<!-- vale on -->

## [1.23.0] - 2026-07-12

<!-- vale off -->

### Added

- **FigurativeHolds**: New rule. Flags "holds" as a possession verb for
  abstractions: a chart that "holds the same wide spread," a result
  that "holds across datasets," a claim that "holds up under
  scrutiny," an approach that "holds great promise," "the correlation
  still holds." Gated on the figurative complement or a curated
  abstract subject, so literal holding (hands, jars, court sessions)
  stays quiet; "holds its own" remains in AnthropomorphicJustification.
- **FigurativeRides**: New rule. Flags "rides" as a dependence and
  piggybacking verb ("everything rides on this migration," "the fix
  rides along with the release," "the cache rides on top of Redis,"
  "riding the wave of adoption"). Complement-gated in the
  FigurativeSits mold, so literal riding (buses, horses) stays quiet;
  disable the rule for transit or equestrian writing.
- **FigurativeCarries**: New rule. Flags "carries" as a freighting
  verb ("carries baggage," "carries significant risk," "carries a
  caveat," "carries the day," "one test carries the suite").
  Complement-gated, so literal carrying (bags, freight) stays quiet;
  "carries its weight" remains in AnthropomorphicJustification.
- **FigurativeRuns**: New rule. Flags "runs" on curated figurative
  complements only, since software literally runs everywhere: "runs
  deep," "runs counter to," "runs the gamut," "runs the risk of,"
  "ran its course," "running on fumes," "hit the ground running,"
  and the pervasion shape ("one limit runs under the whole table,"
  "a theme runs through the essay"). Literal senses ("run the
  tests," "the server runs on port 8080," "up and running") never
  match; "run a tight ship" remains in ShipOveruse.

### Changed

- **OrganicConsequence**: Add the effortless-emergence shape where a
  result "falls straight out of" its premise ("the design fell straight
  out of the constraints"). The manner adverb (straight, right,
  cleanly, directly, naturally) is the gate, so a literal "the pen fell
  out of my pocket" stays quiet.
- **AnthropomorphicJustification**: Add "hinges on" alongside the
  existing "hangs on" arm ("the whole plan hinges on a single
  assumption," "hinges on whether"), gated on the same abstract
  complements so a literal door hinge stays quiet.
- **AnthropomorphicJustification**: Add the adjudication family, where
  a fact gets the gavel: "availability settles the question," "the
  benchmark decides the debate," "latency puts the matter to rest,"
  "laid the issue to rest." Human settling ("we settled on a date,"
  "the team settled in") stays quiet.

<!-- vale on -->

## [1.22.2] - 2026-07-12

<!-- vale off -->

### Fixed

- **CataphoricForecasting**: Fire on title-case headings. The bare
  cardinal-subject shape required lowercase words after the count, so
  "Three Layers Guard an EDA" as a heading stayed silent while its
  sentence-case twin fired. The words after the cardinal now allow
  capitals and the temporal lookahead matches case-insensitively, so
  "Two Weeks Notice" still stays clean. A cardinal-led proper noun
  ("Three Mile Island") now fires; add a project exception where
  those recur.

<!-- vale on -->

## [1.22.1] - 2026-07-12

<!-- vale off -->

### Fixed

- **CommitFileListing**: Fire on the lists agents actually write. The
  per-line terminator required a newline after every bullet, but Vale
  hands raw text to the regex without a trailing newline on the last
  line, so a three-bullet list came up one repetition short and the
  rule never fired on its own test case. The terminator now accepts
  end-of-text, and the whitespace atoms no longer cross line
  boundaries. Paths wrapped in backticks or bold markers and paths
  with a trailing annotation ("src/app.ts: add handler") now count as
  file bullets too.

<!-- vale on -->

## [1.22.0] - 2026-07-12

<!-- vale off -->

### Changed

- **ContrastiveFormulas**: Add the bare appositive contrast ("a
  refinement, not a rivalry"). The clause tokens all require a subject
  and a verb, so the verbless form slipped through in prose and never
  fired in headings. The new token needs no verb and fires in both
  places, and it subsumes the single-word-subject "X is a Y, not a Z"
  token, which is removed.
- **CataphoricForecasting**: Add bare cardinal-opener shapes with no
  curated noun or verb: the determiner-led count ("The three axes"),
  the sentence-initial count subject ("Eight repos seed the list"),
  and the folksy proportion ("three of every four runs," "nine times
  out of ten"). Temporal and partitive openers ("Three years ago,"
  "The two weeks of onboarding," "The three of us") stay clean via
  lookahead. A legitimate back-reference now fires ("The two functions
  return different types"); drop the count or add a project exception.
  The message now mentions measured figures as well as items.
- **AnthropomorphicJustification**: Broaden the lexicon beyond the
  fixed idioms. New families: the bare grant with a curated object
  list ("earns a caveat," "earned the name"), coronation ("crowns the
  release," "crowning achievement"), rank-claiming gated on trophy
  objects ("claims the top spot," "stakes a claim") so a paper that
  claims a result stays clean, and agency verbs ("behaves itself,"
  "pretends otherwise," "cares deeply," "delivers on its promise,"
  "hangs on a single assumption," "hangs in the balance").
- **VerbTricolon**: Reword the message so it does not open with a
  spelled-out cardinal, which the broadened CataphoricForecasting now
  flags.

<!-- vale on -->

## [1.21.2] - 2026-07-09

<!-- vale off -->

### Changed

- **HeadingTitleCase** (experimental): Exempt ordinal heading prefixes
  through the capitalization extension's `prefix` field. Labels such as
  "Section 1:", "Appendix A", and "Chapter IV" no longer read as Title
  Case, and neither do bare numeric ordinals ("1.1", "2."), with or
  without a trailing colon. The rule still checks the remainder of the
  heading, and the first word after the prefix still needs its capital
  letter. Recognized labels: Appendix, Chapter, Example, Figure, Part,
  Phase, Section, Stage, Step, and Table, each followed by a number, a
  single letter, or a roman numeral. The README now documents copying
  the rule into a project-owned style to change the prefix or the
  built-in exceptions, since `vale sync` overwrites packaged styles;
  word-level exceptions keep working through the project vocabulary.

<!-- vale on -->

## [1.21.1] - 2026-07-07

<!-- vale off -->

### Changed

- **FigurativeLands**: Add a subordinator-gated arrival shape. A temporal
  or conditional subordinator ("once," "when," "whenever," "after,"
  "before," "until," "if," "as soon as"), a short subject, then the verb
  with no destination preposition ("once the feature lands," "when the PR
  lands," "until the fix lands"). The subordinator does the gating: the
  bare form floods, so only the subordinated form fires. The shared
  exceptions still apply, so a plane or a bird stays quiet.

<!-- vale on -->

## [1.21.0] - 2026-07-01

<!-- vale off -->

### Added

- **FigurativeSits**: New rule. Flags "sits" used to place an abstraction
  rather than a physical object ("sits at the intersection of design and
  research," "sits alongside the incumbent," "the responsibility sits with
  the platform team," "the migration ticket just sits there"). The sibling
  of FigurativeLands, but the calculus flips: literal sitting is everywhere
  (people, pets, furniture, and buildings all sit), so the rule gates on the
  complement after the verb instead of the subject. Each token curates one
  figurative sense: conceptual placement ("sits at the core of"), spectrum
  range ("sits somewhere between"), an adverb plus a relational preposition
  ("sits squarely within scope"), companion or ranking pairing ("sits
  alongside," "sits atop," "sits astride"), the rests-with and within-scope
  idioms ("the decision sits with the board"), dormancy ("sits idle," "sits
  in isolation," "sits in limbo"), acceptance ("does not sit right"),
  emotional weight ("sits heavy"), opposition ("sits at odds with"), and
  noun-gated layer-stack and priority senses ("sits above the database
  tier," "sits at the top of the backlog"). Literal sitting ("the cat sits
  on the mat," "the cabin sits on the ridge") stays quiet; disable the rule
  for furniture, cartography, or page-layout writing. "At the heart of"
  stays with PromotionalPuffery to avoid a double flag.

<!-- vale on -->

## [1.20.1] - 2026-06-30

<!-- vale off -->

### Changed

- **CataphoricForecasting**: Add a process-decomposition shape. A
  progression or split verb, a preposition, then a mid-sentence cardinal
  and a sequential-structure noun ("expands in three phases," "breaks
  down into four stages," "is split into three phases"). The count sits
  mid-sentence and lowercase, the shape the capitalized rules exclude on
  purpose; the verb and the sequential noun together gate out the
  ordinary count and the "three-tier" architecture reference. The noun
  set stays to phase-like scaffolding, so a literal split into physical
  parts or pieces does not fire.
- **CataphoricForecasting**: Add the categorization companion shape. Same
  grammar as the process-decomposition shape, with a grouping verb and a
  non-sequential grouping noun ("falls into three categories," "breaks
  down into four groups," "is sorted into two buckets"). The grouping
  noun set is disjoint from the sequential one, so the two shapes never
  fire on one clause.

<!-- vale on -->

## [1.20.0] - 2026-06-30

<!-- vale off -->

### Added

- **CataphoricForecasting**: New rule. Flags the numbered lead-in that
  announces a count of items and then enumerates them ("Three pillars
  support this strategy," "Four user journeys define the experience,"
  "Here are the four options," "There are three reasons this matters").
  Three shapes: a capitalized cardinal plus a curated framework noun, a
  capitalized cardinal plus a noun phrase plus a forecasting verb, and the
  listicle pivot ("Here are the four ...," "The following five ...," a short
  cardinal-led clause ending in a colon). The tell is a lead-in, so the count
  is the sentence-initial subject; the capitalized cardinal excludes the
  ordinary mid-sentence number ("all three files," "about five minutes,"
  "the four corners of the map"). The forecasting-verb shape can fire on a
  literal count subject ("Four wheels drive the axle") and a few scaffold
  nouns carry literal senses ("Three levers control the press"); disable the
  rule for mechanical or hardware writing. Vale has no cross-block lookahead,
  so it cannot confirm the list that follows and leans on the sentence-initial
  position instead.

- **LabelAndExplain**: New rule. Flags the "noun-phrase label:
  explanatory sentence" construction ("The dominant attendee report:
  developers build from scratch because finding an existing extension
  is harder than writing a new one."). A determiner-led label of up to
  four lowercase words, a colon, then a lowercase clause of 20 or more
  characters ending in sentence punctuation. The lowercase clause leaves
  the capitalized "Label: Sentence" case to ColonUsage; the length
  requirement skips short values ("The output: green.") and dotted file
  lists; a lookbehind skips copula clause-labels ("The following options
  are available: ..."). A capitalized noun-phrase label needs
  part-of-speech tagging to catch and stays out of scope, because a
  Vale sequence cannot require a token after a skip gap.

### Changed

- **RhetoricalDevices**: The "The X:" dramatic-colon labels ("The catch:,"
  "The takeaway:," "The upshot:," and the rest) moved to LabelAndExplain,
  which now owns the "Label: sentence" construction. They still fire
  whatever follows the colon, so they keep catching the short and
  capitalized continuations the structural token skips. The question and
  test patterns ("Ask yourself:," "The test:") stay in RhetoricalDevices.

<!-- vale on -->

## [1.19.0] - 2026-06-12

<!-- vale off -->

### Added

- **ColonUsage**: New rule. Replaces Google.Colons, which lints heading
  text too and flags the title half of "Appendix A: Glossary". The rule
  keeps the lowercase-after-colon check but exempts headings (ATX and
  setext) through a negated scope, and it skips acronyms, the pronoun
  "I", quotations, and clock times. Vale strips markup before matching,
  so a run-in bold label still flags; disable the rule where that
  convention is established.

### Changed

- The repository's own Vale config disables ColonUsage for its own docs
  and commit messages, which use the run-in bold label convention.

### Fixed

- Lint errors that predated this release in CLAUDE.md, TODO.md, and the
  doc-lint skill.
- The stale rule count in the CLAUDE.md project overview.
- The README now spells out "regular expressions" where it said "regex".

<!-- vale on -->

## [1.18.0] - 2026-06-11

<!-- vale off -->

### Added

- **PassiveVoice** (experimental): New sequence rule. Flags passive
  constructions where the participle directly follows the auxiliary
  ("was eaten," "is called," "has been made"). The participle slot
  requires a past-participle tag from Vale's part-of-speech tagger, so
  predicate adjectives ("the results were mixed," "the talk was indeed
  useful," "the color is red") stay clean, unlike the regex rules in
  Google and write-good. Carries no exception list: conventional
  technical passives ("is deprecated," "is required") fire too, and
  users decide what to except.
- **PassiveVoiceAdverb** (experimental): New sequence rule. Companion
  for the adverb-gap shape ("was never used," "is automatically
  generated," "was not merged"), which the regex rules miss entirely
  because they allow only whitespace between the auxiliary and the
  participle.
- **PassiveDensity** (experimental): New Tengo rule. Flags a section
  when at least 3 sentences, and more than 35 percent of them, contain
  a passive construction. Occasional passive voice is ordinary English;
  sustained passive voice across a section is the fingerprint of AI
  formal register, and no per-instance rule can see it.

### Changed

- The repository's own Vale config disables Google.Passive,
  write-good.Passive, and write-good.E-Prime in favor of the new
  passive voice rules.

<!-- vale on -->

## [1.17.1] - 2026-06-11

<!-- vale off -->

### Added

- **EmptyPaddingStacked**: New rule. A three-token companion to
  EmptyPadding that catches an empty modifier with an adjective ahead of
  the noun, such as "named operational support" or "certain strategic
  concerns." EmptyPadding stays on the bare modifier-noun pair; this rule
  covers the stacked shape, since Vale sequences cannot make the
  adjective slot optional.

<!-- vale on -->

## [1.17.0] - 2026-06-11

<!-- vale off -->

### Added

- **EmptyPadding**: New rule. Flags an empty modifier before a noun the
  noun does not need: "named stakeholders," "various stakeholders,"
  "respective roles," "given task," "certain constraints," "particular
  concerns." Sequence-based (modifier plus noun) and deliberately broad,
  so it also catches literal uses such as "named pipe," "various
  reasons," and "a certain amount." Suppress per-section where the
  literal sense is common.

<!-- vale on -->

## [1.16.0] - 2026-06-03

<!-- vale off -->

### Added

- **StrategyBuzzwords**: New rule. Flags strategy-deck buzzword
  metaphors: "growth flywheel," "competitive moat," "north star
  metric," "network effects," "first-mover advantage," "land grab."
  Each term is scoped to its figurative shape so the literal homograph
  stays clean (the engine's flywheel, a castle's moat, the real North
  Star). Network effects and first-mover advantage are the most
  legitimate as analytical terms and are the first to drop if they fire
  on genuine analysis.

<!-- vale on -->

## [1.15.0] - 2026-06-03

<!-- vale off -->

### Added

- **FigurativeAnchor** (experimental): New rule. Flags "anchor" used
  figuratively to ground an abstraction ("anchored in our values,"
  "anchor the strategy," "an emotional anchor," "serves as an anchor").
  Lives in the experimental package at `warning` because anchor is
  heavily homographic: the HTML anchor tag, a news anchor, a ship's
  anchor, an anchor tenant, and the anchoring bias are all literal and
  stay clean. Exemptions cover the physical objects something anchors to
  (a wall, the seabed); the rest leans on the figurative shape.

<!-- vale on -->

## [1.14.0] - 2026-06-02

<!-- vale off -->

### Added

- **FigurativeLands**: New rule. Flags "lands" used as an overused
  arrival verb ("the request lands on the node," "the PR lands in
  main," "where the idea lands") and exempts the common things that
  literally land (planes, spacecraft, birds, balls, snow, skydivers,
  territory nouns). The list is intentionally not exhaustive: rare
  landers fire, so aviation or nature writing disables the rule. Built
  on a broad match plus an exemption list because Vale's RE2 engine has
  no lookbehind, so the rule cannot scope by negative subject.
  Exemptions carry an inline
  case-insensitive flag because `ignorecase` covers tokens but not
  exemptions. Known limitation: the infinitive "to land on" fires
  (the matched subject is "to"), which suits the figurative sense but
  catches literal "to land on the runway."
- **ShipOveruse**: New rule. Flags "ship" as an AI overuse fingerprint:
  the release verb ("ship it," "ship fast," "ship the feature") and the
  maritime clichés ("run a tight ship," "the ship has sailed").
  Deliberately broad with no exemptions, so the logistics verb ("ship
  the order") and the vessel noun ("a cargo ship") are flagged too. Word
  boundaries keep the `-ship` suffixes (relationship, leadership) and
  compounds (spaceship, flagship) clean. Disable the whole rule for
  maritime or logistics prose.
- **ResonateOveruse**: New rule. Flags "resonate" as an overused
  reception verb ("resonates with audiences," "resonates deeply").
  Flagged broadly with no exemptions; the only literal sense is physics
  and acoustics, a clear domain that disables the whole rule. The noun
  forms "resonance" and "resonant" are a different word and stay clean.
- **SemicolonUsage**: New rule. Catches the semicolon used as an
  em-dash substitute: the punchy, comma-free, clause-final continuation
  an agent reaches for after the em-dash gets flagged. Following
  Google's guidance, it exempts the legitimate uses, which carry a comma
  (a series with internal punctuation, a "; however," join, a complex
  clause) or a conjunctive adverb. Several internal rule messages were
  reworded to drop their own semicolons.
- **GrowthMetaphors**: New rule. The startup-as-organism register:
  "incubate," "gestate," "nascent," "fledgling," "embryonic,"
  "cultivate," "nurture," and "in its infancy" are flagged broadly. The
  finance and tech-overloaded words are scoped to their startup phrases
  ("minimum viable," "seed funding," "organic growth") so the random
  seed, a viable option, and organic produce stay clean. Disable for
  medical or nature writing.
- **ContrastiveNegation**: New rule. Catches the telegraphic negation
  cadence agents reach for once "not X; it's Y" gets flagged: stacked
  "no setup, no config, no hassle" and the single clause-final fragment
  "cleartext repo names, no k-anonymity gate." Aggressive by design, so
  it also fires on a literal "coffee, no sugar"; disable it for terse
  spec lists. "No longer" and "no sooner" are exempt as temporal
  adverbs.

### Changed

- **ColloquialAssessments**: Drop the release-verb token ("lands in
  main") and the "lands at just the right" token, both now covered by
  FigurativeLands. The assessment sense ("the joke lands") stays.
- **OverusedVocabulary**: Add marketing and hype verbs (supercharge,
  unleash, turbocharge, democratize). The `-ed` forms of super and
  turbocharge are omitted so the literal "supercharged engine" stays
  clean.
- **Rule messages**: Standardize every diagnostic message to the
  `AI <label>: '%s'. <action>.` shape and add a RuleMessage view so the
  messages lint themselves (`just lint-messages`).

<!-- vale on -->

## [1.13.1] - 2026-05-28

<!-- vale off -->

### Added

- **AnthropomorphicJustification**: Add a "harm" family — `does harm`,
  `doing harm`, `does no harm`, `without doing harm`, `causes harm`,
  `causing harm`, and the `without causing harm` form. Treats
  inanimate subjects as moral agents capable of inflicting or
  withholding damage; technical prose rarely needs the Hippocratic
  register. Legitimate in medical / health-software writing, where
  the rule can be disabled per file via `.vale.ini`.

<!-- vale on -->

## [1.13.0] - 2026-05-28

<!-- vale off -->

### Added

- **AnthropomorphicJustification**: Extend the "paying" family with
  `pays its rent`, `paid its rent`, `paying its rent`. Same metaphor
  as `earns its keep` and `pays for itself` — treats inanimate
  subjects as tenants justifying their place.
- **ExplainerHeadings**: Add the `What It X` family alongside the
  `Why It X` shapes. Covers `What It Solves`, `What This Solves`,
  `What It Does`, `What This Does`. Same explanatory-throat-clearing
  register — the heading restates the section's job rather than
  doing it.

### Changed

- **StackedAnaphora**: Extend the 2- and 3-sentence indefinite-article
  exemplification stack patterns to accept `An` as well as `A`.
  Catches mixed pairs like `An unset X counts as Y. A set-but-wrong
  value belongs to Z.`
- **MicDrop**: Broaden the bare-`Not X.` one-word-verdict rule to
  also catch the bare `No X.` form (`No singleton.`, `No daemon.`,
  `No fallback.`, etc.). Replaced the v1.12.0 enumerated tail list
  with `Not? \w+\.` — accepts more conversational false positives
  (`No way.`, `Not bad.`) in exchange for full coverage of the
  AI register without maintaining a token list.
- **MicDrop**: Extend the verb-led contrastive family to non-linking
  verbs with noun objects. `They share a contract, not code.`,
  `Custom signals belong in stderr text, not in the exit number.`
  Covers `share`, `keep`, `hold`, `live`, `belong`, `sit`, `point`,
  `go`, `give`, `take` with optional prepositional heads
  (`in`, `on`, `to`, `at`, `with`, `for`).
- **MicDrop**: Catch the comparative aphorism mic-drop
  (`Disk costs less than lost context.`) — subject + verb +
  comparative adjective + `than` + object + period. Concise,
  sentence-final, in the AI tutorial-blog tone. Covers `more`,
  `less`, `fewer`, `faster`, `slower`, `cheaper`, `cleaner`,
  `simpler`, `safer`, `tighter`, `better`, `worse`, `larger`,
  `smaller`, `bigger`, `higher`, `lower`, `longer`, `shorter`.
- **ParallelStaccato**: Add multi-word-subject negation-parallel
  pairs — `Concurrent readers don't block each other. One writer
  at a time doesn't block readers.` Existing patterns only handled
  single-word subjects; this extends to 2-5 word noun phrases on
  both sides of the pair.
- **README**: Document the inline-code-stripping limitation. Vale
  strips inline-code content before applying regex rules, so AI
  tells whose subjects are wrapped in backticks (`` `session` ``,
  `` `PreToolUse` ``) silently slip past several `StackedAnaphora`
  patterns. Tested `scope: raw` against a 376-file corpus; gained
  14% more catches but also fired on repetition inside code blocks
  and on pattern-documentation. Not worth the FP cost.

<!-- vale on -->

## [1.12.0] - 2026-05-28

<!-- vale off -->

### Added

- **AnthropomorphicJustification**: Cover bare `does the work` /
  `doing the work`. Originally excluded as too prone to human-subject
  false positives, but in practice legitimate human uses tend to come
  with qualifiers (`the work of three people`), contrast (`does the
  work, gets no credit`), or relative clauses (`the team that does
  the work`). The bare construction with a non-human subject
  (`the CLI does the work`) is distinctive enough to flag.
- **MicDrop**: Extend the pronoun mic-drop family (`It matters.`,
  `This compounds.`) to explicit noun-phrase subjects. Covers
  `The/This/That [noun] matters.`, `compounds.`, `pays off.`,
  `adds up.` and the plural `These/Those [noun] matter.` family.
  Subjects allow up to three words and tolerate hyphens, so shapes
  like `The unset-versus-bogus distinction matters.` are caught.
- **AnthropomorphicJustification**: Add a `deserves`/`deserve`
  family. Covers older idiomatic shapes (`deserves a closer look`,
  `deserves mention`, `deserves scrutiny`) and the gerund tell
  (`deserves noting`, `deserves exploring`, `deserves unpacking`,
  `deserves confirming`, `deserves revisiting`) that treats
  inanimate subjects as moral agents owed consideration.
- **RhetoricalDevices**: Add the dramatic-colon `The X:` family —
  terse noun-colon constructions where AI manufactures a drumroll
  instead of writing `The X is...`. Covers `The price:`,
  `The catch:`, `The kicker:`, `The upshot:`, `The tradeoff:`,
  `The trick:`, `The cost:`, `The downside:`, `The flip side:`,
  `The bottom line:`, `The takeaway:`, `The result:`,
  `The answer:`, `The reason:`, `The lesson:`, `The moral:`,
  `The point:`, `The pitch:`, `The fix:`, `The payoff:`.
- **AICompoundPhrases**: Add the `real` intensifier family for
  abstract nouns where AI inflates weight: `a real choice`,
  `a real option`, `a real difference`, `a real test`,
  `a real question`, `a real chance`, `a real problem`,
  `real value`, `real progress`, `real flexibility`,
  `real ownership`, `real accountability`, `real tradeoffs`,
  and similar. Enumerated rather than bare `real` to avoid
  `real-time`, `real estate`, `real world` collisions.
- **StackedAnaphora**: Add 3-sentence indefinite-article
  exemplification stacks — `A [noun] [verb]s ... A [noun] [verb]s
  ... A [noun] [verb]s ...` — the shape AI reaches for when
  enumerating hypothetical scenarios. The construction predates
  LLMs in API/concurrency reference docs but is now a sufficiently
  strong AI tell to flag uniformly.
- **StackedAnaphora**: Add the 2-sentence parallel-mirror variant
  of the same shape (`A session write lands in X. A subagent
  write lands in Y.`). The shared-verb framing carries the
  drumroll even with only two sentences.
- **ExplainerHeadings**: Add `Why It Exists` and `Why This Exists`
  alongside the existing `Why It Matters` / `Why This Matters`
  pair. Same explanatory-throat-clearing register.
- **MicDrop**: Catch the verb-led contrastive form that appears as
  a remediation cheat after the bare `X, not Y.` fragment gets
  flagged. Shape: `[Subject] [linking verb] [adjective], not
  [adjective].` Linking verbs include `stays`, `remains`,
  `becomes`, `feels`, `reads`, `seems`, `sounds`, `looks`,
  `appears`, `grows`, `ends up`, `comes across`. Example:
  `Isolation here stays logical, not physical.` Lives in MicDrop
  alongside the bare-fragment form so the same family triggers
  the same message.
- **StackedAnaphora**: Catch verbless definite-article noun-list
  fragments — `The X, the Y, the Z.` (3+ items, asyndetic or
  syndetic). Items may be up to 5 words to tolerate parenthetical
  glosses like `Time-To-Live (TTL)`. Requires sentence-initial
  capital `The` to reduce mid-sentence false positives on
  legitimate enumerations.
- **StackedAnaphora**: Catch the `Whether X, or whether Y.`
  subordinate-clause fragment — a `whether... or whether...`
  pair promoted to a standalone sentence with no main clause.
  Also catches the two-sentence variant
  `Whether X. Whether Y.` (anaphoric paired fragments).
- **MicDrop**: Extend the parallel noun-phrase fragment family
  to comparative adjectives — `Stronger isolation, more lifecycle
  machinery.`, `Faster delivery, fewer surprises.` Covers
  `Stronger`, `Weaker`, `Faster`, `Slower`, `Better`, `Worse`,
  `Cleaner`, `Simpler`, `Smaller`, `Larger`, `Bigger`, `Higher`,
  `Lower`, `Tighter`, `Looser`, `Smoother`, `Newer`, `Older`,
  `Richer`, `Leaner`, `Safer`, `Saner`, `More`, `Less`, `Fewer`.
- **MicDrop**: Catch the bare `Not X.` one-word-verdict fragment
  (`Not now.`, `Not yet.`, `Not necessarily.`, `Not magic.`,
  `Not optional.`, `Not random.`, `Not arbitrary.`, etc.).
  Enumerated tail to keep conversational `Not bad.` / `Not good.`
  responses from firing unless they sit in the tell register.
- **ServesAsDodge**: Catch the colon-cheat copula-replacement —
  `The candidate mechanism: a hook on Bash that...` where AI has
  swapped `is` or `are` for a colon to dodge weak-verb or
  passive-voice lints. Same anti-`is` evasion as the
  `serves as a` / `stands as the` patterns, just performed with
  punctuation. Triggered by a 4+ word definite-NP subject,
  indefinite article after the colon, and 6+ token descriptive
  content so short pedagogical `X is: Y` answers stay quiet.
- **AICompoundPhrases**: Add the investigation-thread family
  (`threads to pull on`, `thread to pull on`, `loose threads
  to pull`, `loose threads to chase`, `another thread to pull`,
  etc.) and the solidification-metaphor family
  (`before/after [X] hardens` / `hardened` / `solidifies` /
  `solidified` / `ossifies` / `ossified`). Both are AI
  tutorial-blog vocabulary that recurs in design docs and
  pre-release write-ups.

### Changed

- **README**: Document three structural patterns Vale can't
  reliably flag — noun-phrase + past-participle fragments
  (`The same set, applied identically by every client...`),
  adjective-led fragments without an explicit subject
  (`Durable enough for coordination state, without...`), and
  headless-infinitive section openers
  (`Threads to pull on in X before Y hardens.`). All three
  need syntactic parsing beyond regex token matching. Some
  characteristic vocabulary of the third shape now fires via
  `AICompoundPhrases`, but the structure itself stays beyond
  reach.

<!-- vale on -->

## [1.11.0] - 2026-05-27

<!-- vale off -->

### Added

- **RedundantPrecaution**: New rule for a redundant-precaution idiom
  that has graduated to AI-cliché status in public discourse. Narrow
  scope by design — covers the flagship spaced form (`belt and
  suspenders`) and its hyphenated adjectival form
  (`belt-and-suspenders`). Neighboring patterns in the same register
  (`for good measure`, `out of an abundance of caution`, `cover all
  the bases`, `just to be safe`) were intentionally omitted; they may
  land in a follow-up if the cluster proves coherent.

<!-- vale on -->

## [1.10.0] - 2026-05-26

<!-- vale off -->

### Added

- **WrapUpHeadings**: New heading-scoped rule for closing-flourish
  headings that summarize what the section already said. Covers
  `Final Thoughts`, `Closing Thoughts`, `Parting Thoughts`, `Wrapping
  Up`, `Wrap-Up`, `Wrap Up`, `Putting It All Together`, `Bringing It
  All Together`, `Tying It All Together`, `The Big Picture`, `The
  Bottom Line`, `The Takeaway`, `Final Word`, `Last Word`, and `Final
  Take`. Conventional one-word headings like `Conclusion`, `Summary`,
  and `Overview` were intentionally omitted to avoid false positives
  on standard documentation structure.
- **ExplainerHeadings**: New heading-scoped rule for tutorial-blog
  heading clichés. Covers `Deep Dive`, `Under the Hood`, `Demystifying`,
  `Why It Matters`, `Why This Matters`, `A Closer Look`, and `The
  Inner Workings`. The `X 101` pattern was considered but omitted
  because Go RE2 lacks the lookahead needed to exclude legitimate uses
  like `Highway 101` or `Route 101`.
- **MarketingHeadings**: New heading-scoped rule for promotional-
  register headings. Covers `The Ultimate Guide`, `Everything You
  Need to Know`, `Mastering`, `Unlocking`, `The Power of`, `The
  Magic of`, `Why Choose`, `The Future of`, `The Art of`, `The
  Science of`, `A Game-Changer`, and `Revolutionizing`. `Transforming`
  was considered but omitted as too operational (`Transforming Data
  with X` is a legitimate heading shape).
- **AnnouncementHeadings**: New heading-scoped rule for headings that
  narrate content delivery instead of delivering it. Covers `What
  You'll Learn` / `What You Will Learn`, `What We'll Cover` / `What
  We Will Cover`, `What to Expect`, `What We're Building` / `What We
  Are Building`, and `Here's What You'll Get` / `Here's What You Get`.
  Navigation-style sections like `What's Next` and `Next Steps` were
  intentionally omitted because they serve a real navigation purpose
  in READMEs.

<!-- vale on -->

## [1.9.0] - 2026-05-20

<!-- vale off -->

### Added

- **ColloquialAssessments**: New rule for knowing-tone verdicts that
  surface as recurring AI tells in casual technical writing. Covers
  figurative landing of jokes, points, and analogies (anchored to a
  narrow noun list plus `really lands` and `actually lands`); anchored
  move-as-verdict shapes like `is the move`, `that's the move`, `the
  right move`, and `the play here`; and rhetorical wind-ups about what
  counts most (`what really matters`, `all that matters`, `the only
  thing that truly matters`). Chess analysis where `Nf3 is the move`
  is the natural phrasing is documented as a known per-section
  limitation.

### Changed

- **AnthropomorphicJustification**: Extended to cover structural-
  importance descriptors (`load-bearing`, `load bearing`) and a
  qualified work-doing family (`does the real work`, `doing the
  important work`, `does most of the work`, and so on). Bare work-doing
  patterns without the qualifier were intentionally omitted to avoid
  matching legitimate human-subject sentences such as "engineers do the
  work."
- **AICompoundPhrases**: Extended with needle-moving variants (`move`,
  `moves`, `moved`, `moving the needle`, plus `nudge the needle`
  forms) and capability-unlocking shapes (`unlocks new`, `unlocks the
  potential`, `unlocks the power`, `unlocks the value`, `unlocks
  capabilities`, `unlocks possibilities`).
- **NarrativePivots**: Extended with industry-altering rhetoric
  (`changed the game` and `changed the landscape` variants),
  rule-overhauling (`rewrote the rules`, `rewrote the playbook`), and
  script-flipping (`flipped the script`, `moved the goalposts`,
  `shifted the paradigm`).
- **OverusedVocabulary**: Added the sincerity adjective and adverb
  (`genuine`, `genuinely`).
- **FillerPhrases**: Extended the performative-sincerity section with
  honesty-preamble hedges (`I'll be honest`, `to be perfectly honest`,
  `to be completely honest`, `to be totally honest`, `to be brutally
  honest`, `the honest truth`, `my honest take`, `honest answer`, and
  related forms).
- **VocabularySwap** (experimental, warning level): Added
  substitution suggestions for the sincerity adverb (`genuinely` to
  `really` or `truly`), the sincerity adjective (`genuine` to `real`,
  `authentic`, or `true`), and the figurative-enabling verb (`unlock`,
  `unlocks`, `unlocked`, `unlocking` to `enable` variants or `make
  possible`).

<!-- vale on -->

## [1.8.0] - 2026-05-13

<!-- vale off -->

### Added

- **StackedAnaphora**: Extended to cover adverb anchors — always, never,
  fully, completely, entirely, truly, purely, only, and just. Each adverb
  gets a period-separated variant (two parallel sentences sharing the lead
  adverb) and a comma-separated variant (two parallel clauses sharing the
  lead adverb). The comma variant accepts a lowercase second clause so
  colon-led shapes also match.

<!-- vale on -->

## [1.7.0] - 2026-05-11

<!-- vale off -->

### Added

Seven new rules in the `ai-tells-commits` style, bringing the total to 13.

- **CommitTestEnumeration**: Flags scoreboard-style test reporting in commit
  messages such as enumerated pass and fail counts, percentage coverage
  figures, and the catch-all phrases about every test passing or being green.
  Commits should link the CI run instead of restating raw numbers.
- **CommitAttribution**: Flags agent marketing trailers including robot-emoji
  "Generated with" banners, "Co-Authored-By" lines naming Claude, Copilot, or
  Cursor, and the Anthropic noreply email signature. Kernel-style
  `Assisted-by: AGENT:VERSION` trailers remain allowed.
- **CommitPastTense**: Flags past-tense and present-participle verbs on the
  subject line ("Added X," "Fixed Y," "Refactoring Z"). Uses `\A` with
  `scope: raw` so body paragraphs that happen to start with one of these
  verbs are not flagged.
- **CommitChangelogStyle**: Flags Keep-a-Changelog headings inside a single
  commit body (`## Added`, `### Fixed`, `### Breaking Changes`, etc.).
  CHANGELOG.md is the place for that format; commit bodies should explain
  in prose what changed and why.
- **CommitMarketingAdjectives**: Flags marketing intensifiers in commit
  messages ("production-ready," "enterprise-grade," "mission-critical,"
  "battle-tested," "bulletproof"). Four hyphenated tokens already covered
  by `OverusedVocabulary` and `AICompoundPhrases` are intentionally omitted.
- **CommitUnquantifiedClaims** (warning): Flags performance, size, and speed
  claims used without numbers ("significantly faster," "much smaller,"
  "blazingly fast"). Ships at warning rather than error so legitimate
  commits with obvious gains are not blocked.
- **CommitFileListing** (warning): Flags commit bodies that enumerate three
  or more consecutive bullets which look like file paths. The diff already
  shows which files changed; the body should describe what changed about
  the code.

<!-- vale on -->

### Fixed

- **Lint**: Cleaned up pre-existing `Vale.Spelling` and `Google.Semicolons`
  noise by extending the project vocabulary with legitimate technical terms
  and author names, suppressing the leaked `Google.Semicolons` override on
  synced style packages via the `styles/**` section of `.vale.ini`, and
  reworking one paragraph in `EXPERIMENTAL.md` so it stops tripping the
  experimental sentence-length-variance rule.

## [1.6.3] - 2026-03-25

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
  since it's a project-local spelling allowlist, not something consumers need.
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

<!-- vale ai-tells.ShipOveruse = NO -->
- **Release workflow**: `ai-tells-experimental.zip` now ships as its own
  release artifact alongside `ai-tells.zip` and `ai-tells-commits.zip`
<!-- vale ai-tells.ShipOveruse = YES -->

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

<!-- vale ai-tells.ShipOveruse = NO -->
- **Packaging**: `ai-tells-commits` now ships as its own zip asset,
  `ai-tells-commits.zip`, so Vale can install it as a separate package.
  Before, it shipped inside `ai-tells.zip`, which Vale ignored during
  sync because the directory name didn't match the package name.
<!-- vale ai-tells.ShipOveruse = YES -->

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

[1.27.1]: https://github.com/tbhb/vale-ai-tells/compare/v1.27.0...v1.27.1
[1.27.0]: https://github.com/tbhb/vale-ai-tells/compare/v1.26.0...v1.27.0
[1.26.0]: https://github.com/tbhb/vale-ai-tells/compare/v1.25.0...v1.26.0
[1.25.0]: https://github.com/tbhb/vale-ai-tells/compare/v1.24.0...v1.25.0
[1.24.0]: https://github.com/tbhb/vale-ai-tells/compare/v1.23.0...v1.24.0
[1.23.0]: https://github.com/tbhb/vale-ai-tells/compare/v1.22.2...v1.23.0
[1.22.2]: https://github.com/tbhb/vale-ai-tells/compare/v1.22.1...v1.22.2
[1.22.1]: https://github.com/tbhb/vale-ai-tells/compare/v1.22.0...v1.22.1
[1.22.0]: https://github.com/tbhb/vale-ai-tells/compare/v1.21.2...v1.22.0
[1.21.2]: https://github.com/tbhb/vale-ai-tells/compare/v1.21.1...v1.21.2
[1.21.1]: https://github.com/tbhb/vale-ai-tells/compare/v1.21.0...v1.21.1
[1.21.0]: https://github.com/tbhb/vale-ai-tells/compare/v1.20.1...v1.21.0
[1.20.1]: https://github.com/tbhb/vale-ai-tells/compare/v1.20.0...v1.20.1
[1.20.0]: https://github.com/tbhb/vale-ai-tells/compare/v1.19.0...v1.20.0
[1.19.0]: https://github.com/tbhb/vale-ai-tells/compare/v1.18.0...v1.19.0
[1.18.0]: https://github.com/tbhb/vale-ai-tells/compare/v1.17.1...v1.18.0
[1.17.1]: https://github.com/tbhb/vale-ai-tells/compare/v1.17.0...v1.17.1
[1.17.0]: https://github.com/tbhb/vale-ai-tells/compare/v1.16.0...v1.17.0
[1.16.0]: https://github.com/tbhb/vale-ai-tells/compare/v1.15.0...v1.16.0
[1.15.0]: https://github.com/tbhb/vale-ai-tells/compare/v1.14.0...v1.15.0
[1.14.0]: https://github.com/tbhb/vale-ai-tells/compare/v1.13.1...v1.14.0
[1.13.1]: https://github.com/tbhb/vale-ai-tells/compare/v1.13.0...v1.13.1
[1.13.0]: https://github.com/tbhb/vale-ai-tells/compare/v1.12.0...v1.13.0
[1.12.0]: https://github.com/tbhb/vale-ai-tells/compare/v1.11.0...v1.12.0
[1.11.0]: https://github.com/tbhb/vale-ai-tells/compare/v1.10.0...v1.11.0
[1.10.0]: https://github.com/tbhb/vale-ai-tells/compare/v1.9.0...v1.10.0
[1.9.0]: https://github.com/tbhb/vale-ai-tells/compare/v1.8.0...v1.9.0
[1.8.0]: https://github.com/tbhb/vale-ai-tells/compare/v1.7.0...v1.8.0
[1.7.0]: https://github.com/tbhb/vale-ai-tells/compare/v1.6.3...v1.7.0
[1.6.3]: https://github.com/tbhb/vale-ai-tells/compare/v1.6.2...v1.6.3
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
