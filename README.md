# vale-ai-tells

A [Vale](https://vale.sh) package for detecting linguistic patterns commonly associated with AI-generated prose. Based on 2024-2025 research into vocabulary fingerprints and structural tells.

This package targets **technical documentation**, where clarity and directness matter more than style. Less useful for creative writing, marketing copy, or other contexts where some of these patterns may represent intentional choices.

<!-- vale proselint.Annotations = NO -->
> [!NOTE]
> The author created this package to help clean up AI-assisted technical documentation, not to disguise AI-generated content as human-written.
<!-- vale proselint.Annotations = YES -->

[![linted with vale-ai-tells](https://img.shields.io/badge/linted%20with-vale--ai--tells-blue)](https://github.com/tbhb/vale-ai-tells)

## Installation

Add the package to your `.vale.ini`:

```ini
StylesPath = styles
MinAlertLevel = suggestion

Packages = https://github.com/tbhb/vale-ai-tells/releases/download/v1.30.0/ai-tells.zip, \
  https://github.com/tbhb/vale-ai-tells/releases/download/v1.30.0/ai-tells-commits.zip

[*.md]
BasedOnStyles = ai-tells
```

Then run:

```bash
vale sync
```

The `ai-tells-experimental` structural rules install as a separate opt-in package with their own steps, described in [EXPERIMENTAL.md](EXPERIMENTAL.md). The `.vale.ini` at the root of this repository is a development setup that turns on every style at once, so build your own configuration from the install snippet rather than from that file.

## Linting commit messages

<!-- vale ai-tells.OverusedVocabulary = NO -->
<!-- vale ai-tells.AIAdjectiveNounPairs = NO -->
<!-- vale ai-tells-experimental.VocabularySwap = NO -->
AI-generated commit messages show the same fingerprints as AI-generated prose, plus a few tells of their own: self-referential preambles like "This commit adds\u2026," trailing justification clauses like "\u2026ensuring consistency," buzzword adjective combos like "comprehensive tests" and "robust error handling," and gitmoji patterns.
<!-- vale ai-tells-experimental.VocabularySwap = YES -->
<!-- vale ai-tells.OverusedVocabulary = YES -->
<!-- vale ai-tells.AIAdjectiveNounPairs = YES -->

The `ai-tells-commits` style provides 15 rules purpose-built for commit messages, separate from the prose rules so you can opt in without pulling them into your docs.

### Commit message rules

<!-- vale off -->

| Rule | Description |
|------|-------------|
| `CommitSelfReference` | Self-narrating preambles: "This commit adds...," "This PR introduces...," "In this change...," "These changes ensure...," etc. |
| `CommitTrailingJustification` | Trailing clauses that restate the obvious: "...ensuring consistency," "...improving readability," "...which allows for," "for better maintainability," etc. |
| `CommitBuzzwords` | Vague adjective+noun combos: "comprehensive tests," "robust error handling," "proper validation," "various fixes," "relevant components," "necessary changes," etc. |
| `CommitHedging` | Inappropriate uncertainty for changes already made: "This should fix...," "This may help...," "seems to resolve...," etc. |
| `CommitEmoji` | Systematic gitmoji prefixes (✨🐛♻️📝⚡✅🔧🔥🚀 etc.) — emoji commit adoption has jumped from ~25% to ~75% of organizations, driven almost entirely by AI tools. |
| `CommitFigurativeVerbs` | Figurative verbs with an inanimate subject, drawn from commit messages a maintainer rejected: a fix that "arrived," a setting that "carries" a value, a file that "survives" a rebase, a gate that "demands" a clean run, a config that "lives in" a manifest, a message that was "hand-edited." Lives in the commit style rather than the prose style because the subject-plus-verb shape floods ordinary technical writing, where a table really does hold values. |
| `CommitGitJargon` | Bare git nouns used without explanation: "the tree" went red, "the index" still holds the old blob. Not an AI tell but a clarity rule, and the only one here that flags a reader's confusion; the qualified forms ("the working tree," "the git index") name themselves and stay legal. Commit-scoped, since these words mean syntax trees and array indices everywhere else. |
| `CommitOverexplanation` | Filler that pads without informing: "As part of this change...," "The purpose of this commit...," "Summary of changes," "The following changes were made," etc. |
| `CommitTestEnumeration` | Scoreboard-style test reporting: "All 47 tests passing," "Tests: 12 passed, 0 failed," "Coverage: 87%," "100% test coverage," etc. Link the CI run instead. |
| `CommitAttribution` | Agent marketing trailers: robot-emoji "Generated with" lines, "Co-Authored-By: Claude/Copilot/Cursor," "<noreply@anthropic.com>," etc. Use kernel-style `Assisted-by: AGENT:VERSION` instead. |
| `CommitPastTense` | Past-tense or present-participle verbs on the subject line: "Added X," "Fixed Y," "Refactoring Z." Use imperative mood. |
| `CommitChangelogStyle` | Keep-a-Changelog-style headings inside a single commit body: `## Added`, `### Fixed`, `### Breaking Changes`, etc. CHANGELOG.md is the place for that format. |
| `CommitMarketingAdjectives` | Marketing intensifiers: "production-ready," "enterprise-grade," "mission-critical," "battle-tested," "bulletproof," etc. State what changed and why. |
| `CommitUnquantifiedClaims` | Unquantified performance, size, or speed claims: "significantly faster," "much smaller," "blazingly fast," etc. Back claims with numbers. |
| `CommitFileListing` | Three or more consecutive bullets that look like file paths, bare ("src/app.ts"), backticked, bolded, or with a trailing annotation ("src/app.ts: add handler"). The diff already shows files changed; describe what changed about the code. |

<!-- vale on -->

### Setup

Add a `[formats]` section and a dedicated section for the commit message file to your `.vale.ini`:

```ini
[formats]
COMMIT_EDITMSG = md

[{COMMIT_EDITMSG,.git/COMMIT_EDITMSG}]
BasedOnStyles = ai-tells, ai-tells-commits
```

The glob covers both how pre-commit passes the path and direct Vale invocations. Use both styles together: `ai-tells` catches general vocabulary and structural tells, `ai-tells-commits` catches commit-specific patterns.

Add the commit-msg hook to your `.pre-commit-config.yaml`:

```yaml
  - repo: https://github.com/vale-cli/vale
    rev: d32b532e2f5ba703ba06a5a6829f9db1fc78a92c  # frozen: v3.15.2
    hooks:
      - id: vale
      - id: vale
        name: vale (commit message)
        stages: [commit-msg]
        args: [--ext=.md]
```

Install the hook:

```bash
prek install --hook-type commit-msg
```

### Example

A blocked commit:

<!-- vale off -->

```text
$ git commit -m "This commit leverages a comprehensive solution to seamlessly enhance the functionality"

vale (commit message)....................................................Failed
- hook id: vale
- exit code: 1

 .git/COMMIT_EDITMSG
 1:1   error  AI commit tell: 'This commit'. Commit messages shouldn't     ai-tells-commits.CommitSelfReference
              narrate themselves—just state what you did and why.
 1:13  error  AI vocabulary: 'leverages'. Replace with a more specific     ai-tells.OverusedVocabulary
              or common word.
 1:24  error  AI commit tell: 'comprehensive solution'. This vague         ai-tells-commits.CommitBuzzwords
              buzzword combo is a hallmark of AI-generated commits.
 1:48  error  AI vocabulary: 'seamlessly'. Replace with a more specific    ai-tells.OverusedVocabulary
              or common word.
```

<!-- vale on -->

### Suppressing noisy rules

Some prose rules matter less for commit messages. If they generate noise, suppress them in your `.vale.ini`:

```ini
[{COMMIT_EDITMSG,.git/COMMIT_EDITMSG}]
BasedOnStyles = ai-tells, ai-tells-commits
ai-tells.SycophancyMarkers = NO
ai-tells.ClosingPleasantries = NO
```

## Rules included

This package contains 108 rule files covering different categories of AI tells. All rules default to `error` level.

<!-- vale off -->

| Rule | Description |
|------|-------------|
| `AbsoluteAssertions` | AI overconfidence: "the only way to," "the only real solution," "make no mistake," "there is no denying," "above all else," etc. Verify the claim or soften it. |
| `AIAdjectiveNounPairs` | AI adjective immediately preceding a noun: "holistic approach," "seamless integration," "transformative impact," etc. |
| `AICompoundPhrases` | Compound phrases: "rich tapestry," "intricate interplay," "paradigm shift," "double-edged sword," "moving the needle," "unlocks new," etc. |
| `AnnouncementHeadings` | Headings that narrate content rather than being it: "What You'll Learn," "What We'll Cover," "What to Expect," "Here's What You'll Get," etc. |
| `AnthropomorphicCognition` | Cognition and volition handed to an artifact: a spec that "wants" a retry, a release that "teaches" a skill, a dictionary that "learns" a word, a manager that "knows nothing about" a path, a script that "asks whether," a reviewer's tool that "trusts" its inputs, a parser that "gets confused," a workflow that "misbehaves," text "telling the truth." The wanting shape is determiner-gated with human subjects excepted, so "the user wants a report" stays quiet; disable the rule for prose about people, and for machine-learning writing, where a model literally learns. |
| `AnthropomorphicJustification` | Treating abstractions like employees: "earns its keep," "does the heavy lifting," "pulls its weight," "pays for itself," "speaks for itself," "load-bearing," "does the real work," etc. Also the bare grant ("earns a caveat"), the typographic or structural grant ("nothing about the word earns a capital," "the file earns that exemption," "the term earns italics"), coronation ("crowns the release," "crowning achievement"), rank-claiming ("claims the top spot"), and agency verbs ("behaves itself," "pretends otherwise," "cares deeply," "forms an opinion," "delivers on its promise," "hangs on a single assumption," "hinges on whether," reflexive "the query narrows itself," "the config tunes itself," the self-report "declares itself," "announces itself," "proves itself," and the voice figure "speaks up"). Also the adjudication family, where a fact gets the gavel: "availability settles the question," "the benchmark decides the debate," "latency puts the matter to rest," and the same gavel handed an invoice: "the run settled the cost," "squares the ledger," "settles up," "balances the books" (the negotiation sense "settled on a price" stays quiet; disable for restaurant or accounting writing). |
| `AffirmativeFormulas` | Revelation patterns: "Here's the thing," "And that's the beauty of it," "Let that sink in," etc. |
| `CataphoricForecasting` | Numbered lead-ins that announce a count of items and then enumerate them: "Three pillars support this strategy," "Four user journeys define the experience," "Here are the four options," "There are three reasons this matters," etc. Anchored to a sentence-initial capitalized cardinal, so mid-sentence counts ("all three files," "about five minutes") stay clean. The forecasting-verb shape can fire on a literal count subject ("Four wheels drive the axle") and a few scaffold nouns have literal senses ("Three levers control the press"); disable the rule for mechanical or hardware writing. Vale cannot confirm a list actually follows, so sentence-initial position is the proxy for the adjacency. Also the bare sentence- or heading-initial count with no curated noun or verb ("The three axes," "Eight repos seed the list," title-case "Three Layers Guard an EDA") and the folksy proportion ("three of every four runs," "nine times out of ten"). Temporal openers ("Three years ago," "The two weeks of onboarding") stay clean, but a plain count subject fires ("Five people attended") and so does a cardinal-led proper noun ("Three Mile Island"); disable per-file where counts are data or add project exceptions. |
| `ClosingPleasantries` | Sign-off language: "I hope this helps," "Feel free to ask," "Don't hesitate to reach out," etc. |
| `ColloquialAssessments` | Knowing-tone verdicts: "the joke lands," "really lands," "X is the move," "that's the move," "what really matters," "all that matters," etc. |
| `ColonUsage` | A capitalized word after a colon, the "Label: Sentence" construction ("The takeaway: Always test."). Replaces `Google.Colons`, which also lints heading text and flags the title half of "Appendix A: Glossary"; headings are exempt here. Acronyms, the pronoun "I," quotations, and clock times stay clean. Vale strips markup before matching, so run-in bold labels ("**Example:** Like this.") still flag; disable the rule where that convention is established. |
| `ConclusionMarkers` | Formulaic conclusions: "In conclusion," "Ultimately," "At the end of the day," etc. |
| `ContrastiveFormulas` | Rhetorical contrasts: "It's not just X; it's Y," "These aren't X. They're Y," "This doesn't mean X. It means Y," "The real question isn't X; it's Y," "Not only X but also Y," etc. Also the bare appositive "a refinement, not a rivalry," which needs no verb and so fires in headings too. |
| `ContrastiveNegation` | Telegraphic negation cadence that replaces the "not X; it's Y" formula once it gets flagged: stacked "no setup, no config, no hassle" and the single clause-final fragment "cleartext repo names, no k-anonymity gate." Aggressive; it can fire on "coffee, no sugar," so disable it for terse spec lists. |
| `DefensiveHedges` | Preemptive concessions: "This may seem X, but..." "Admittedly, X, but..." "At first glance," etc. |
| `DespiteChallenges` | The "despite challenges" dismissal formula: "despite these challenges," "while challenges remain," "challenges notwithstanding," etc. |
| `DoubleHyphen` | A literal double hyphen, the ASCII stand-in AI types when it cannot produce an em dash. Split from `EmDashUsage` so the fix can differ: backtick it as a CLI flag or literal, or use a real em dash character for punctuation. |
| `EmDashUsage` | Em-dashes, which AI uses excessively |
| `EmphaticCopula` | Italicized copula verbs, determiners, and intensifiers for manufactured profundity |
| `EmptyPadding` | Empty modifiers before a noun the noun does not need: "named stakeholders," "various stakeholders," "respective roles," "given task," "particular concerns," etc. Sequence-based (modifier plus noun), so it casts a wide net and flags literal uses too ("named pipe," "various reasons," "a certain amount"). Deliberately broad; suppress per-section or disable where the literal sense is common. |
| `EmptyPaddingStacked` | The same empty modifiers with an adjective ahead of the noun: "named operational support," "certain strategic concerns," "various regional teams," etc. A three-token companion to `EmptyPadding` for the modifier-adjective-noun shape, since Vale sequences cannot make the adjective slot optional. Same breadth and the same suppression advice. |
| `EnforcementMetaphors` | A check presented as a sentry: a guard that "stands down," a gate left "armed," a linter that "keeps its teeth" or turns "toothless," a workflow that "polices" an arrangement, a formatter that would "fight" the installer, gates that "keep them honest," a grant with no fingerprint "standing behind" it, a skill "standing in the way," "left standing," and a rule that would "flood." Timer arming and literal teeth stay quiet; disable the rule for security or law-enforcement writing. |
| `EvasionMetaphors` | A miss framed as an escape: a defect that "slipped through" or "slips past," a filter that "let it through," a rule people "route around" or "go around," a change that "snuck past" or "sidesteps" a guard, a gap that "went unnoticed" or "goes unreported." "Dodges" and "sails through" stay in `FigurativeIdioms`; disable the rule for clothing, mechanics, or networking prose, where things literally slip and traffic is literally routed around damage. |
| `ExplainerHeadings` | Tutorial-blog heading clichés: "Deep Dive," "Under the Hood," "Demystifying X," "Why It Matters," "A Closer Look," etc. Also the general free-relative heading, a wh-word plus a determiner-gated subject and verb: "Why the Pin Exists," "How the Cache Works," "What the Data Shows." Conventional doc headings ("How to Configure X," "What's New") stay out. |
| `ExplainerLeads` | The same free relative used as a framing device in prose: the cleft lead-in ("Here's what the change does," "This is why the pin matters"), the label before a colon ("What the hook does: it refuses the write"), and the sentence-initial pseudo-cleft ("What the hook does is refuse the write"). Embedded clauses doing real work mid-sentence ("depends on how the shell resolves it") stay out. |
| `FalseBalance` | Evasive "both sides" language: "both sides present valid points," "nuanced approach," etc. |
| `FalseExclusivity` | False insider drama: "nobody talks about," "what most people miss," "the dirty secret," "the elephant in the room," etc. |
| `FigurativeFalls` | "Falls" as an overused verb for shortcoming, membership, and neglect: a result that "falls short," a design that "falls apart," a case that "falls under" a category or "falls within scope," a task that "falls by the wayside" or "through the cracks," a request that "falls on deaf ears," responsibility that "falls to" a team, and the past tenses ("fell short," "had fallen behind"). Gated on the figurative complement, so literal falling (prices, temperature, night, rain) stays quiet; disable the rule for gravity or weather writing. "Fell into place" stays in `NarrativePivots`, and "falls into three categories" stays in `CataphoricForecasting`. |
| `FigurativeHolds` | "Holds" as an overused possession verb for abstractions: a chart that "holds the same wide spread," a result that "holds across datasets," a claim that "holds up under scrutiny," an approach that "holds great promise," "the correlation still holds." Gated on the figurative complement or a curated abstract subject, so literal holding (hands, jars, court sessions) stays quiet; disable the rule for legal or wrestling writing. "Holds its own" stays in `AnthropomorphicJustification`. |
| `FigurativeIdioms` | Fixed figurative phrases standing in for a plain statement of what happened: "costs little," "fares no better," "out of reach," "for want of," "empty slate," "dodges the rule," "survives the rebase untouched," plus the consequence metaphors "where this bites," "sails through," "moving the goalposts," and "blast radius," the reduction idioms "comes down to" and "boils down to," the unpriced tradeoff "comes at a cost" (the named shape "at the cost of performance" stays quiet), the audit formulas "measured cost" and "what remains of" ("what remains is" and "what remains after" stay quiet), the accepted invoice "the cost the rule already accepts," "accepts a small cost," and "tolerated cost," and the substitution verb "stands in for." Another group comes from a retroactive commit-history audit: "closes the gap," "in lockstep," "point of no return," "under its own power," "covers more ground," "brings into line," walking a decision back, main "moving under" a branch, the dogfooding family ("eats its own cooking," "dogfoods," "drinks its own champagne"), "sleeping dogs," and a release "fanning out" into pull requests, with the concurrency nouns "fan-out" and "fan-in" left alone. Whole idioms rather than a gated verb, so no subject gate is needed; disable for runtime and memory-management prose, where a value is literally out of reach, and for placeholder-heavy API prose, where a test double literally stands in for the real thing. |
| `FigurativeQuantities` | Quantity expressed through a physical metaphor instead of a number: the body-part and kitchen dodges for "a few" ("a handful of tests," "a smattering of users," "a sliver of," "a dash of," "a pinch of"), the crowd nouns standing in for "many" ("a slew of," "a host of," "a raft of," "a spate of," "a flurry of," "a litany of," "a laundry list of"), container and landform scale ("a boatload of," "a ton of," "a heap of," "a pile of," "a mountain of"), weather and water scale ("a sea of," "a flood of," "a wave of," "a deluge of," "an avalanche of"), the fancy vague quantities "a myriad of," "a plethora of," "a wealth of," and "a trove of" (the first three migrated from `FillerPhrases`), the mixture metaphors ("a smorgasbord of," "a patchwork of," "a mosaic of," "a constellation of"), and "array" only when an adjective inflates it ("a vast array of"). Each phrase is what a model reaches for when told to remove one of the others, so the whole substitution pool shares one rule and one message. The bare noun "array" stays uncovered as literal everywhere in technical prose; disable the rule for memory-management prose, where objects really do live on a heap, and for networking prose about hosts. |
| `FigurativeDisguises` | The disguise frame, the sibling of the substitution verb in `FigurativeIdioms`: an opinion "disguised as" a question, complexity "masquerading as" rigor, a rewrite "dressed up as" a refactor, a fix "parading as" a feature, an ad "posing as" a review, a form "pretending to be" a conversation, "what passes for" documentation, a wrapper that "passes itself off as" the original, a spreadsheet "cosplaying as" a database, plus the noun forms "in disguise," "under the guise of," "in sheep's clothing," and the stacked impostors "in a trench coat." The verbs match inflected forms only, so the noun homographs (a party disguise, a masquerade ball, a parade route, salad dressing) stay quiet; the comparison shape ("poses as much risk as it removes"), the mathematical "posed as," the bare "passes for the wrong reason," and the literal impersonation of the Windows security API all stay uncovered. Disable the rule for security or forensics prose, where malware really is disguised as an invoice, for emulation and test-double prose, where a mock is built to pretend, and for costume writing. |
| `FigurativeLands` | "Lands" as an overused arrival verb: "the request lands on the node," "the PR lands in main," "where the idea lands." Also catches the prepositionless arrival after a temporal or conditional subordinator ("once the feature lands," "when the PR lands," "until the fix lands"), the perfect and adverbial arrival ("the fix has finally landed," "support landed upstream," "lands as a single commit"), the bare arrival at a clause boundary ("once merged, the fix lands."), and the transitive landing ("landed a fix," "landing it means"). Exempts common literal landers (a plane, a bird, a probe) and the achievement and athletic idioms ("landed a job," "lands the jump"); rare ones fire, so disable the rule for aviation or nature writing. |
| `FigurativeCarries` | "Carries" as an overused freighting verb: a term that "carries baggage," a change that "carries significant risk," an approach that "carries a caveat," one test that "carries the suite," and an inanimate component treated as a vessel for abstract cargo ("the daemon carries no pipeline logic," "the packet carries the payload," "the signal carries data"), or as the bearer of a policy rather than the place it is written ("the lower block carries the pattern," "the config carries the exemption"). Also the typographic cargo ("carries a repotools prefix," "carries a suffix"), the mirrored possession ("carries the same caveat"), and an open determiner-gated subject with the common literal carriers (trucks, couriers, viruses, wires, Go's own Context) listed as exceptions, so "the manifest carries the pin" fires whatever the complement. The phrasal "carries out" (execute) and "carried over" (bring forward) stay quiet, and the arithmetic carry noun never matches; disable the rule for freight, logistics, biology, electrical, or arithmetic writing. "Carries its weight" stays in `AnthropomorphicJustification`. |
| `FigurativeRides` | "Rides" as an overused dependence verb: "everything rides on this migration," a fix that "rides along" in a release or "rides alongside" a bump, an edit that "rides through" on an exemption, a cache that "rides on top of" Redis, a launch "riding the wave," and an operation treated as a passenger on the infrastructure it uses ("the query rides the index," "the lookup rides the cache"). Gated on the figurative complement, so literal riding (buses, horses) stays quiet; disable the rule for transit or equestrian writing. |
| `FigurativeQuiet` | "Quiet" as an overused word for personified inaction: a check that "stays quiet," a log that "goes quiet," a handler that "quietly drops" the error, "quietly ships," "quietly falls back." Gated on the construction (an inanimate subject going silent, or "quietly" ahead of an action verb), so literal quiet (a room, a person, the `quiet` flag) stays quiet; disable the rule for prose about sound. |
| `FigurativeLoud` | The mirror of `FigurativeQuiet`: "loud" as an overused word for personified emphasis. A check that "fails loudly," a linter that "loudly complains," a metric that "sends a loud signal," a warning that comes through "loud and clear." Gated on the construction ("loudly" ahead of an action verb, or an emphasis idiom), so literal loudness (a room, music, a noise) and bare "out loud" (reading, thinking) stay quiet; disable the rule for prose about sound. |
| `FigurativeRuns` | "Runs" gated hard on figurative complements, since software literally runs everywhere: "runs deep," "runs counter to," "runs the gamut," "runs the risk of," "runs circles around," "ran its course," "running on fumes," "hit the ground running," and the pervasion shape ("one limit runs under the whole table," "a theme runs through the essay"). Everyday literal senses ("run the tests," "the server runs on port 8080," "up and running") never match; disable the rule for athletics or plumbing writing. "Run a tight ship" stays in `ShipOveruse`. |
| `FigurativeWins` | "Wins" as an overused verb framing a choice as a contest: an approach that "wins the day," a design that "wins out," a refactor that is "a quick win," "a winning combination," "for the win." Gated on the curated idiom, so the precedence sense ("last write wins," "the more specific rule wins") and literal winning (a team, a game) stay quiet; disable the rule for sports or gaming writing. |
| `FigurativeSits` | "Sits" as an overused placement verb: "sits at the intersection of," "sits alongside," responsibility that "sits with" a team, work that "sits idle." Mostly gated on the figurative complement, so literal sitting stays quiet. One token gates on the subject instead, catching a document or config element placed by "sits" where "is" would do ("the entry sits in the config block," "the word changelog sat in the proper-noun list"); disable the rule for furniture, cartography, page-layout, or memory-layout writing. |
| `FigurativeStrikes` | "Strikes" as an overused verb for resonance and aptness: an argument that "strikes a chord," a critique that "strikes at the core of" the design, a phrase that "strikes the right tone," a rewrite that "struck gold." Gated on the figurative complement, so literal striking (a match, lightning, a labor strike) stays quiet; disable the rule for labor or percussion writing. "Strike a balance" stays in `FalseBalance` and "at the heart of" stays in `PromotionalPuffery`. |
| `FigurativeLends` | "Lends" as an overused verb for conferring an abstract quality: a structure that "lends itself to" reuse, a study that "lends credence," a detail that "lends weight." Gated on the figurative complement, so literal lending (money, a book) stays quiet; disable the rule for library or finance writing. |
| `FigurativeDraws` | "Draws" as an overused verb for sourcing and comparison: an argument that "draws on" prior work, a section that "draws a distinction," a heading that "draws attention to" a caveat, a post that "draws to a close." Gated on the figurative complement, so literal drawing (a card, water, a weapon, blood) stays quiet; disable the rule for art or card-game writing. |
| `FigurativeCasts` | "Casts" as an overused verb for projecting an abstraction: a finding that "casts doubt on" a result, a decision that "casts a long shadow," a rewrite that "casts a wide net." Gated on the figurative complement, so literal casting (a fishing line, metal, a vote, actors) stays quiet; disable the rule for fishing, metalwork, or theater writing. |
| `FigurativeClears` | "Clears" as passing described as a jump: a draft that "clears the gate," a message that "cleared every check," a fix "clearing a finding," a branch that "clears CI." Gated on the checking noun after the verb, so clearing a cache or a screen stays quiet; disable the rule for athletics writing, and for interface prose where clearing an alert means dismissing it. |
| `FigurativeFires` | "Fires" as an overused verb for a check doing its job: a rule that "fires," hooks that "fire on every commit," an alert that "never fires." Gated on a checking-or-alerting subject, so the timers and events pre-LLM systems prose gives this verb ("the timer fired," "the event fires") stay quiet, along with guns and kilns; disable the rule for firearms or ceramics writing. |
| `FigurativeTrips` | "Trips" as an overused verb for setting off a check: prose that "trips the rule," a flag that "trips the linter," writing that "still trips it." Gated on the checking object, so "round-trip a string," "trip the detector," and "trip the barrier" (established systems usage) stay quiet; disable the rule for electrical or hiking writing. |
| `FigurativeSees` | "Sees" as an overused witness verb: a library that "sees heavy use," an endpoint that "saw a spike in errors," a year that "saw the introduction of" a feature, a project that "has seen its fair share." Gated on the complement, so literal seeing stays quiet; disable the rule for prose about eyesight. "Never sees" stays in `CommitFigurativeVerbs`. |
| `FigurativeTravels` | "Travels" as an overused journey verb for transmission: a request that "travels through the stack," data that "travels," a pattern that "travels well." Gated on the subject or the route complement, so literal travel stays quiet; disable the rule for transit or physics writing. |
| `FigurativeBreeds` | "Breeds" as causation given a biological verb: complexity that "breeds confusion," inconsistency that "breeds distrust," "a breeding ground for" bugs. Gated on the abstract offspring, so literal breeding (dogs, livestock, mosquitoes) stays quiet; disable the rule for husbandry or biology writing. |
| `FigurativeDemands` | "Demands" as obligation issued by an abstraction: a migration that "demands care," an edge case that "demands attention," an interface that "demands a closer look." Gated on the complement, so a person demanding a refund and the economics noun stay quiet; disable the rule for labor or economics writing. The determiner-gated bare shape ("the gate demands a clean run") stays in `CommitFigurativeVerbs`. |
| `FigurativeLives` | "Lives" as location by residence: config that "lives in" a file, logic that "lives upstream," truth that "lives in one place," "where the exemption lives." An open determiner-gated subject with the beings that literally reside (families, species, neighbors) listed as exceptions, so the residence figure fires whatever the artifact; the pre-LLM programmer idiom ("the package lives in") fires by design. Disable the rule for biography or housing writing. |
| `FigurativeOwns` | "Owns" as responsibility by possession: a tool that "owns" a directory, a rule that "owns" a phrase, an installer that "owns" the deployed tree, "the owning rule." The concurrency and memory register (a goroutine owns a lock, a caller owns a buffer) and legal ownership (copyright, trademarks) sit in the exceptions; disable the rule for prose about resource lifetimes. |
| `FigurativeStays` | "Stays" as personified restraint: a check that "stays green," a helper that "stays out of the way," a fix that "stays clear of" the hot path, work that "stayed behind" on an assumption, deciding "what stays in and what stays out." Gated on the complement, so a guest staying at a hotel stays quiet; disable the rule for lodging or travel writing. "Stays quiet" stays in `FigurativeQuiet`. |
| `FigurativeSurfaces` | "Surfaces" as discovery by emergence: drift that "surfaces" on a change, an audit that "surfaced a defect," "nothing surfaced this earlier." Gated on a complement or a defect-family subject, so the API surface and the road surface stay quiet; disable the rule for marine or graphics writing. |
| `FigurativeSweeps` | "Sweeps" as an overused verb for wholesale motion: a change that "sweeps away" the old behavior, a refactor making "sweeping changes," a problem "swept under the rug," reviewers "swept up in" the excitement, a trend that "swept through" the industry, plus the totality idioms "a clean sweep," "in one sweep," and "one fell swoop." Gated on the figurative complement, so the garbage collector's mark-and-sweep, a parameter sweep, and a radar sweep stay quiet, and the audit-pass noun ("a sweep over the docs") stays uncovered as established programmer usage; disable the rule for housekeeping or weather writing. |
| `FigurativeReaches` | "Reaches for" as selection described as motion: prose that "reaches for the same verb," a rule that "reached for a curated list," AI that "reaches for this structure," writers who "reach for a metaphor." An open determiner-gated subject with the beings and limbs that literally reach (hands, children, climbers, robot arms) listed as exceptions, a curated bare-subject shape for "AI reaches for," and a complement gate on the writing-device nouns whatever the subject. "Out of reach" stays in `FigurativeIdioms` and "reach out" in `ClosingPleasantries`; disable the rule for sports or robotics writing. |
| `FigurativePays` | The transaction figure: effort as spending, benefit as a purchase, consequence as a bill, with the goods left blank. Work that "pays off," a shortcut where you "pay the price," a change that "buys you flexibility" or "buys us time," "the price of admission," "foots the bill," "puts a premium on," "cashes in on." The named tradeoff pre-LLM prose writes ("at the cost of performance," "pay the price of building the map") stays quiet, so only the unpriced transaction fires; disable the rule for finance or commerce writing. "Pays for itself" and "pays dividends" stay in `AnthropomorphicJustification`, and the sentence-final "It pays off." also belongs to `MicDrop`. |
| `FillerIntensifier` | "single" and its cousins riding a determiner that already carries the count: "a single command," "every single time," "no single point of failure," "any single failure," "any one of the checks," "the single source of truth," "a lone exception," "its sole purpose," "a mere formality," "one solitary warning," "a singular focus." Deliberately broad: "no single component owns this" is flagged too, and recasting it takes more than deletion. Hyphenated compounds ("a single-threaded server"), grammar's "the singular form," pronoun heads ("no one," "each one," "every one"), and `AbsoluteAssertions`' "the single most important" stay out. |
| `FillerPhrases` | Padding and performative sincerity: "a wide range of," "in order to," "honestly," "to be perfectly honest," "the honest truth," etc. |
| `FormalRegister` | Overly formal vocabulary: "utilize," "facilitate," "commence," etc. |
| `FormalTransitions` | Formal transitions: "Moreover," "Furthermore," "What's more," "Case in point," etc. |
| `GrowthMetaphors` | The startup-as-organism register: "incubate," "gestate," "nascent," "fledgling," "embryonic," "cultivate," "nurture," "in its infancy," plus scoped startup phrases ("minimum viable," "seed funding," "organic growth"). Disable for medical, nature, or agricultural writing. |
| `HedgingPhrases` | Compulsive hedging: "It's important to note that," "That being said," "Generally speaking," "As you might expect," etc. |
| `HollowAcknowledgment` | The staged-insight antithesis that names a thing and then declines to act on it: "names the gap without filling it," "identifies the problem without solving it," "raises the question without answering it," plus the shorthand "all analysis, no action." Gated on a notice-verb, a "without" gerund, and a back-referring pronoun, so an ordinary "left without saying goodbye" stays quiet. Distinct from `ContrastiveFormulas`, which negates a category rather than an action. |
| `HouseStyle` | The "house" compound for a project's own conventions: "the house style," "house tics," "the house formula," "the house voice," "house idioms." Agent prose picks up the figure whenever it writes about a repo's rules. The core style's one substitution rule, so each finding carries its mechanical drop-in correction ("project style," "project tics") and the fix tooling can apply it without judgment. The hyphenated compound stays quiet: "our in-house style guide" is in-house + style, not this figure. |
| `IncompleteComparison` | An intensified comparative missing its second term: "significantly lower risk," "substantially faster," "dramatically better results." A comparison has two terms, and AI prose habitually asserts the first and drops the second, leaving the reader to guess the baseline. A sentence that supplies it ("faster than the old parser," "lower compared with the previous release," "versus," "relative to") stays clean. Overlaps `OverusedVocabulary` on "significantly" and `FormalTransitions` on sentence-initial "Notably," so one span can raise two alerts; each rule still reads correctly on its own in a consumer's config. |
| `LabelAndExplain` | The "noun-phrase label: explanatory sentence" construction ("The dominant attendee report: developers build from scratch because finding an existing extension is harder than writing a new one."). A determiner-led label of up to four lowercase words, a colon, then a lowercase clause of 20 or more characters ending in sentence punctuation. The lowercase clause leaves the capitalized "Label: Sentence" case to `ColonUsage`; the length requirement skips short values ("The output: green.") and dotted file lists; a lookbehind skips copula clause-labels ("The following options are available: ..."). Also holds the curated dramatic-colon labels ("The catch:," "The takeaway:," "The upshot:") moved from `RhetoricalDevices`, which fire whatever follows the colon. A capitalized label ("The Redis cache: it evicts...") needs part-of-speech tagging to catch and stays uncovered. |
| `ListIntroductions` | Announcements of upcoming lists or summaries: "Below you'll find," "Here's a breakdown of," "Here's everything you need to know," "The following sections will," etc. |
| `MarketingHeadings` | Promotional-register heading clichés: "The Ultimate Guide," "Everything You Need to Know," "Mastering X," "Unlocking X," "The Power of X," "The Future of X," "Revolutionizing X," etc. |
| `Metacommentary` | Throat-clearing and self-commentary that narrates the text rather than adding content |
| `MicDrop` | Short dramatic sentences for manufactured emphasis in technical prose: "It matters." "Full stop." "And it shows." Contrastive fragments: "Dense, not cramped." Preference fragments: "Clarity over cleverness." Imperative mic-drops: "Trust the process." Categorical declarations: "Density is a feature." |
| `MicDropHeadings` | Tagline-style headings: "Clarity, not cleverness," "Simple, then fast," "Speed over correctness," "X first, Y second," etc. |
| `NarrativePivots` | Unearned dramatic pivots: "something shifted," "everything changed," "that changed everything," "changed the game," "rewrote the playbook," "flipped the script," "it was a wake-up call," etc. |
| `NegatedObject` | The spec-sheet negation, a verb with "no" moved onto its object: "allows no inline suppression," "makes no clock calls," "offers no guarantee," "requires no configuration," "poses no risk," "collects no telemetry," "leaves no trace," "knows no bounds." Idiomatic prose negates the verb instead ("doesn't allow inline suppression"). The "zero" spelling of the same move fires too ("requires zero configuration," "adds zero overhead"), while literal counts ("zero or more," Go's "zero value") stay quiet. The verb list is curated against pre-LLM corpora, so ordinary docs formulas with other verbs ("takes no arguments," "returns no value," "has no effect," "contains no cycles") stay quiet, as do degree idioms ("no more than," "fares no better," "starts no earlier than") and the pronoun "no one." Human idioms built on the listed verbs ("makes no sense," "needs no introduction") still fire; add project exceptions where a file needs them. "Make no mistake" stays in `AbsoluteAssertions`, "do no harm" in `AnthropomorphicJustification`, and "carries no" in `FigurativeCarries`. |
| `NegatedSubject` | The passive sibling of `NegatedObject`, the negated claim promoted to subject: "No configuration is required," "No data is collected," "No breaking changes are introduced," plus the elliptical badge copy "No signup required," "No credit card needed." Anchored to a sentence-initial capital "No," so the lowercase docs conditional ("if no timeout is specified, the default applies") stays quiet, as do the spec formulas "No error is returned," "No exception is raised," and "No whitespace is allowed," the degree and pronoun shapes ("no longer needed," "no one was harmed"), and the active past verb ("No law required them to file"). The human caveat register with kept predicates ("No other validation is performed," "No attempt is made") still fires; add project exceptions where a file needs them. |
| `NominalizedScopeChange` | The change-as-noun: "the widening covers the inflections," "after the narrowing, alerts stay identical," "the tightening of the gate," "this broadening adds three tokens." Naming an edit by its direction of travel instead of naming the rule and what it catches now. Gated on a determiner plus a scope-change gerund followed by punctuation, a preposition, or a common predicate verb, so the adjectival reading ("the widening gap," "a narrowing conversion") stays quiet. Prose about type narrowing or compiler conversions disables the rule. |
| `NounString` | Four consecutive common nouns: "the customer feedback analysis pipeline stalled," "the incident response playbook revision deadline slipped." A noun string compresses relationships that a phrase with prepositions or verbs would state outright, leaving the reader to reconstruct them. Like `CommitGitJargon`, a clarity rule rather than a statistical tell. A negated leading token anchors each stack to its start, so a longer stack raises one alert instead of one per four-noun window; the anchored part-of-speech tag keeps proper nouns out ("New York City Hall" stays clean); temporal nouns the tagger files as nouns ("yesterday," "today") never match. The threshold is four because three-noun compounds saturate technical prose ("config file path," "unit test suite"). Known edges: the tagger reads some verbs as plural nouns ("the unit test suite runs" registers a fourth noun), a stack that opens a paragraph has no anchor token and goes unseen, and established four-noun compounds ("database connection pool size") fire, so add project exceptions where those are entrenched. |
| `OpeningCliches` | AI-style openings: "In today's rapidly evolving landscape," "Without further ado," "Whether you're," etc. |
| `OrganicConsequence` | False inevitability: "emerges naturally," "a natural consequence," "follows naturally from," and the effortless-emergence shape where a result "falls straight out of" its premise. The manner adverb gates the emergence shape, so a literal "the pen fell out of my pocket" stays quiet. |
| `OverusedVocabulary` | Words with documented AI overuse: "delve," "comprehensive," "unprecedented," "sophisticated," "salient," "efficacy," "paramount," "cognizant," "camaraderie," "palpable," "fleeting," "amidst," "genuinely," "genuine," "supercharge," "unleash," "democratize," etc. Verb forms (leverage, harness, etc.) moved to `OverusedVocabularyVerbs`. |
| `OverusedVocabularyVerbs` | Verb forms of AI vocabulary fingerprints: "leverage," "navigate," "showcase," "harness," "embark," "foster," "spearhead." Sequence-based for precision — noun forms such as "financial leverage" do not trigger. |
| `ParallelStaccato` | Back-to-back minimal sentences with parallel structure: "Engineers build. Managers ship." "Content carries the personality. Chrome doesn't." Solo two-word staccato: "Complexity scales." |
| `ParticipialPadding` | Present participle (-ing) phrases appended for shallow analysis: "highlighting its importance," "reflecting broader trends," "underscoring its role," "solidifying its position," etc. The #1 discriminating feature in the PNAS study (527% of human rate). |
| `PromotionalPuffery` | Ad-copy and travel-brochure language: "nestled in," "vibrant community," "a beacon of," "renowned for its," "has emerged as a," "left an indelible mark," etc. |
| `RedundantPrecaution` | Redundant-precaution idioms that signal over-engineering thinking: "belt and suspenders," "belt-and-suspenders," and the British "belt and braces." |
| `ResonateOveruse` | "Resonate" as an overused reception verb: "resonates with audiences," "resonates deeply." Flagged broadly; the only literal sense is physics and acoustics, so disable the rule for physics or audio writing. |
| `RestatementMarkers` | Redundant restatements: "In other words," "Simply put," "To be more specific," etc. |
| `RhetoricalDevices` | Rhetorical question patterns: "Ask yourself:", "The test:", "When doing X, ask:" etc. |
| `RhetoricalSelfAnswer` | Self-posed rhetorical questions answered for dramatic effect: "The result/catch/worst part?" followed by an immediate answer. |
| `SelfReference` | Self-referential cross-references: "as mentioned above," "as noted earlier," "as we'll explore," etc. |
| `SemicolonUsage` | Semicolons used as an em-dash substitute: a comma-free, clause-final continuation ("It does one thing; it does it well."). Exempts the legitimate uses, which carry a comma (lists with internal punctuation, "; however," joins, complex clauses). `Google.Semicolons` still warns on the rest. |
| `SequencingMarkers` | Formulaic ordinal sequencing: "Firstly," "Secondly," "Thirdly," "The first takeaway," "The second benefit," etc. |
| `ServesAsDodge` | Inflated copula replacements: "serves as a," "stands as the," "represents a pivotal," "boasts a vibrant," etc. Use "is" or "are" instead. |
| `ShipOveruse` | "Ship" as an AI overuse fingerprint: the release verb ("ship it," "ship fast," "ship the feature") and the maritime clichés ("run a tight ship," "the ship has sailed"). Deliberately broad with no exemptions, so the logistics verb and the vessel noun are flagged too. Disable the rule for maritime or logistics writing. |
| `StackedAnaphora` | Stacked repetition for emphasis: "No X. No Y. No Z." "It's X. It's Y. It's Z." etc. |
| `StackedHedges` | A modal verb doubled with an epistemic adverb: "could potentially," "may possibly," "might conceivably." The modal already carries the uncertainty, and restating it is reflex, not caution; one hedge per claim, tied to a number where one exists, says more. Modal-first order only, so the idiomatic tail of "she did all she possibly could" stays quiet, and a single hedge ("this could break," "possibly affects") never fires. |
| `StrategyBuzzwords` | Strategy-deck buzzword metaphors: "growth flywheel," "competitive moat," "north star metric," "network effects," "first-mover advantage," "land grab." Each is scoped to the figurative shape, so the engine's flywheel, a castle's moat, and the real North Star stay clean. |
| `StructureAnnouncements` | Narrating upcoming structure: "key takeaway," "quick recap," "to recap," "quick summary," "to put it plainly," "to put this in perspective," etc. |
| `SycophancyMarkers` | Flattering phrases: "Great question," "I'm happy to help," "You make an excellent point," etc. |
| `UniversalObject` | The mirror of `NegatedObject`, the universal quantifier on the object: "handles all edge cases," "covers every scenario," "addresses all concerns," "eliminates all ambiguity," "meets every requirement," "passes all checks," "guarantees all deliveries." The self-grading register where a change claims a clean sweep. The verb list is curated against the same pre-LLM corpora, so the operations family stays quiet ("returns all matches," "removes all elements," "finds all occurrences" are spec facts), along with the lock-comment register ("protects all fields"), doctest report output ("passed all tests"), the exception idiom ("eliminates all but the top level"), and the alternation reading of "every other." Base verb forms stay out, so modal and infinitive aspiration ("should handle all cases," "to cover all of them") never fires. Human coverage prose on the listed verbs ("Handles all POST requests") still fires; add project exceptions where a file needs them. |
| `UniversalSubject` | The passive sibling of `UniversalObject`, the universal quantifier promoted to subject: "All edge cases are handled," "Every concern has been addressed," "All inputs are validated," "Every effort has been made," plus the uncounted scoreboard "All tests pass," "All checks are green." Anchored to a sentence-initial capital, so the mid-sentence conditional ("when all bytes are consumed") stays quiet, as do adjective predicates ("All three parts are optional"), the resumptive floats that summarize a list just named ("X, Y, and Z are all copied," "have all been observed"), and the modal future ("All feedback will be addressed"). Unlike its siblings, the predicate slot is open (any participle) rather than corpus-curated: the docs uniformity sweep ("All tabs are expanded to spaces," "All whitespace is removed") flags on purpose, the same call as the figurative family, because the shape now floods AI prose. Add project exceptions where spec formulas are deliberate. The counted scoreboard ("All 47 tests passing") stays in `CommitTestEnumeration`. |
| `UnpackExplore` | Explainer announcements: AI's habit of announcing what it is about to explain rather than just explaining it. Phrases beginning with "Let me" or "Let us" followed by unpack, break down, dive in, walk through, examine, explore, etc. |
| `UrgencyInflation` | False urgency and importance assertions: "cannot be overstated," "more important than ever," "has never been more critical," "the stakes have never been higher," "at a critical juncture," "in an increasingly connected world," etc. |
| `VagueAttributions` | Claims attributed to unnamed authorities: "experts argue," "studies show that," "research suggests," "a growing body of evidence," etc. |
| `VerbTricolon` | Exactly-three parallel verb lists: "build, test, and deploy," "define, validate, and transform," etc. |
| `VerbTricolonDensity` | Multiple verb tricolons in one paragraph — LLM prose clusters exactly-three enumerations. |
| `WrapUpHeadings` | Closing-flourish headings: "Final Thoughts," "Closing Thoughts," "Wrapping Up," "Putting It All Together," "The Big Picture," "The Bottom Line," "The Takeaway," etc. |

<!-- vale on -->

## What to write instead

Quick substitution reference for the most common patterns:

<!-- vale off -->

| Instead of | Write |
|---|---|
| `delve into` | `look at`, `cover`, `examine` |
| `leverage` (verb) | `use`, `apply`, `build on` |
| `utilize` | `use` |
| `seamlessly` | *(delete)* |
| `comprehensive` | *(delete, or name what's included)* |
| `in order to` | `to` |
| `Moreover` / `Furthermore` | `Also`, `And`, or start a new sentence |
| em-dash | comma, period, or parentheses |
| `It's important to note that` | *(delete — just state the point)* |
| `I hope this helps` | *(delete)* |

<!-- vale on -->

## Using with AI agents

Each error message gives AI agents, and humans alike, specific, usable guidance to fix issues immediately. Messages include:

- A short prefix for quick identification: `AI hedge:`, `AI filler:`, and similar labels
- The matched text
- A concrete action: delete, rewrite, replace, or use a simpler word

Example workflow with an AI coding assistant:

```text
You: Run `vale docs/` and fix any warnings or errors you find.

Agent: Running vale... Found 4 issues:

1. docs/intro.md:5 - AI opening: 'In today's rapidly evolving'.
   Start with your actual point instead of this generic lead-in.
2. docs/intro.md:12 - AI vocabulary: 'delve'.
   Replace with a more specific or common word.
3. docs/intro.md:12 - AI punctuation: em-dash detected.
   Use a comma, period, or parentheses instead.
4. docs/guide.md:8 - AI filler: 'in order to'.
   Delete this phrase—it adds no meaning.

Fixing these now...

[Agent edits the files, replacing generic phrases with specific content]

Running vale again... No issues found.
```

## Customization

Disable specific rules:

```ini
[*.md]
BasedOnStyles = ai-tells
ai-tells.FormalTransitions = NO
ai-tells.EmDashUsage = NO
```

Change severity levels:

```ini
[*.md]
BasedOnStyles = ai-tells
ai-tells.HedgingPhrases = error
```

### Copying HeadingTitleCase into your own style

The experimental [HeadingTitleCase rule](EXPERIMENTAL.md#headingtitlecase) needs more per-project tuning than any other rule in the package, and most of its settings only live in the rule file itself. Word-level exceptions (product names in your headings) work through the project vocabulary, as [EXPERIMENTAL.md](EXPERIMENTAL.md#headingtitlecase) describes. Everything else sits in fields that `.vale.ini` can't override: the built-in exceptions list and the ordinal prefix pattern that recognizes labels like `Section 1:` and `Appendix A`. And `vale sync` overwrites packaged styles on every run. Edits to the synced copy don't survive.

To own those settings, copy the rule into a style your project controls and turn off the packaged copy:

```bash
mkdir -p styles/MyProject
cp styles/ai-tells-experimental/HeadingTitleCase.yml styles/MyProject/
```

```ini
[*.md]
BasedOnStyles = ai-tells, ai-tells-experimental, MyProject
ai-tells-experimental.HeadingTitleCase = NO
```

## Early prevention with AI agent instructions

If you use an AI coding assistant, add instructions to your project's `CLAUDE.md`, `AGENTS.md`, or similar file to prevent Vale violations before they happen:

```markdown
## Writing style

When writing or editing prose:

- Avoid AI vocabulary fingerprints: "delve," "tapestry," "multifaceted,"
  "leverage," "foster," "underscores," "comprehensive," "robust"
- Don't open with generic phrases like "In today's rapidly evolving..."
- Skip hedging ("It's important to note...") and filler ("in order to")
- Use commas or periods instead of em-dashes
- Cut sycophantic openers: "Great question!" "Absolutely!"
- Prefer simple words: "use" not "utilize," "help" not "facilitate"
- Start paragraphs with your actual point, not rhetorical wind-up
```

## Limitations

This package catches lexical and phrasal patterns. It can't detect:

- Sentence-length uniformity, or burstiness
- Perplexity scores
- Paragraph-length patterns
- Semantic analysis
- Model-specific stylometric signatures

### Known patterns not covered

<!-- vale ai-tells.OverusedVocabulary = NO -->
<!-- vale ai-tells.EmDashUsage = NO -->
<!-- vale ai-tells.VerbTricolon = NO -->
<!-- vale ai-tells.AICompoundPhrases = NO -->
<!-- vale Google.EmDash = NO -->
<!-- vale Google.Latin = NO -->

AI writing research documents these patterns, but they need analysis beyond Vale's token-matching capabilities:

- **Sentence-length uniformity:** AI produces sentences of near-uniform length, roughly 27 words, while human writing varies widely. Requires statistical analysis across the document.
- **Paragraph-length uniformity:** AI paragraphs tend toward uniform size, typically 3-5 sentences and 60-100 words each. Requires document-level measurement.
- **Dead metaphor repetition:** AI latches onto one metaphor and repeats it 5-10 times throughout a piece. Requires tracking metaphor usage across the document.
- **One-point dilution:** One argument restated 10 ways across thousands of words — circular repetition that reads as comprehensiveness. Requires semantic analysis.
- **Elegant variation:** AI's repetition-penalty pushes it to substitute synonyms unnaturally, cycling through "protagonist," "key player," "eponymous character" instead of reusing a name. Requires NLP-level analysis.
- **Content duplication:** Repeating entire sections or paragraphs verbatim within the same piece. Requires document-level diff analysis.
- **Unnecessary inline definitions:** AI habitually inserts appositive definitions like "X, a [definition], does Y" even when the audience already knows the term. Too many false positives for token matching.
- **Invented concept labels:** AI appends abstract problem-nouns like "paradox," "trap," "creep," and "divide" to domain words and treats them as established terms. Too many legitimate uses for token matching.
- **Noun-phrase + participial-phrase fragments:** AI drops fragments built from a noun phrase and a trailing past-participle modifier ("The same set, applied identically by every client on every open.") as paragraph closers. Distinguishing them from legitimate appositive constructions requires syntactic parsing.
- **Adjective-led sentence fragments:** AI ends paragraphs with adjective-led fragments that lack an explicit subject or verb ("Durable enough for coordination state, without the full-sync cost on every commit."). Without dependency parsing, regular expressions can't separate these from valid continuations of a prior sentence's subject.
- **Headless-infinitive openers:** AI opens sections with a noun + infinitive-modifier fragment ("Threads to pull on in Claude Code before the surface hardens.") that reads as a section title punctuated as a sentence. Catching the structure requires distinguishing it from legitimate noun-phrase headings, which regular expressions can't do reliably. Some of the vocabulary that recurs in these fragments (thread-pulling metaphors, solidification metaphors) is now covered by `AICompoundPhrases`.
- **AI tells with inline-code subjects.** Vale strips inline code (`` ` `` `code` `` ` ``) from prose before applying regular-expression rules, so patterns like the `A X verbs ... A Y verbs ...` parallel-mirror or `No X, no Y.` anaphora silently fail when the subject contains an identifier wrapped in backticks — common in technical documentation. Switching the rule to `scope: raw` would catch them but also fires on repetition inside code blocks and on documentation that quotes example patterns. The marginal coverage gain isn't worth the new FP sources.

<!-- vale ai-tells.OverusedVocabulary = YES -->
<!-- vale ai-tells.EmDashUsage = YES -->
<!-- vale ai-tells.VerbTricolon = YES -->
<!-- vale ai-tells.AICompoundPhrases = YES -->
<!-- vale Google.EmDash = YES -->
<!-- vale Google.Latin = YES -->

For fuller detection, combine this package with statistical analysis tools.

### Supplementing with AI agent instructions

Vale can't detect structural patterns like sentence uniformity or paragraph rhythm. If you use an AI coding assistant, add instructions to your project's `CLAUDE.md`, `AGENTS.md`, or similar file to cover what Vale misses:

```markdown
## Writing style

When writing or editing prose, vary your structure:

- Mix sentence lengths: follow long explanations with short punchy statements
- Vary paragraph lengths—not every paragraph needs 3-4 sentences
- Avoid the "topic sentence, three supporting points, conclusion" formula
- Don't start consecutive paragraphs or sentences with the same word
- Skip the "In conclusion" wrapper—just end when you're done
- Let some points stand alone without hedging or qualifications
- Be willing to be direct, even blunt, rather than diplomatically balanced
```

This covers structural patterns that lexical analysis can't catch.

## Working on this repository

Every gate runs through a mise task, and CI runs the same tasks against the same pinned tools, so a clean local run predicts a clean pull request.

```bash
mise run bootstrap  # vendir sync, install the toolchain, vale sync, install the git hooks
mise run lint       # ryl, rumdl, biome, cspell, vale, tombi, mise fmt, editorconfig-checker
mise run test       # fixture guard: tells fire, subjects smoke-test, false positives stay clean
mise run check      # lint and test together
```

Most of the toolchain and the tasks that run it arrive from [`repotools`](https://github.com/tbhb/repotools) as a vendored payload: [vendir.yml](vendir.yml) names the tag, [vendir.lock.yml](vendir.lock.yml) records the commit it resolved to, and `vendir sync` writes the tool pins to `.config/mise/conf.d/` and the shared tasks to `.repotools/tasks/`. [mise.toml](mise.toml) holds what is specific to this repository and overrides any shared pin by name. Each configuration locks its downloads by digest beside itself, in [mise.lock](mise.lock) and `.config/mise/mise.lock`, so a contributor and CI run the same binaries. `mise run repotools:check-toolchain` measures the installed tools against those lockfiles, and `mise run repotools:check-vendored` catches a vendored file edited in place or a sync nobody committed. Both fail rather than warn. No gate needs a container runtime.

Commit messages go through the shared [`repotools`](https://github.com/tbhb/repotools) gates at the `commit-msg` stage. One hook enforces the Conventional Commits shape and the length bounds. Another enforces the trailer rules, including a DCO `Signed-off-by` on every message. The remaining pair spell-check the buffer and lint it with this package's own `ai-tells` and `ai-tells-commits` styles. [AGENTS.md](AGENTS.md) describes the drafting workflow and the prose-lint output contract.

`mise run build-package` writes the three release zips locally, and `mise run release vX.Y.Z` tags, pushes, and waits on the release run before rewriting the notes from the changelog.

## Sources

Based on academic research, practitioner analysis, and community-maintained catalogs of AI writing patterns:

<!-- vale off -->

### Academic research

- [Delving into ChatGPT usage in academic writing through excess vocabulary](https://arxiv.org/abs/2406.07016) (arXiv, 2024) — Identifies specific words with statistically significant overuse in AI-assisted academic writing.
- [Distinguishing academic science writing from humans or ChatGPT with over 99% accuracy](https://pmc.ncbi.nlm.nih.gov/articles/PMC10328544/) (PMC, 2023) — Demonstrates that stylometric features can reliably distinguish AI from human academic prose.
- [Do LLMs write like humans? Variation in grammatical and rhetorical styles](https://www.pnas.org/doi/10.1073/pnas.2422455122) (PNAS, 2025) — Analyzes 67 grammatical and rhetorical features across human and LLM text; identifies present participial clauses as the strongest discriminator (527% of human rate in GPT-4o).

### Pattern catalogs

- [tropes.fyi — AI Writing Tropes Directory](https://tropes.fyi/directory) — Categorized catalog of 33+ named AI writing tropes with examples and community contributions.
- [Wikipedia — Signs of AI writing](https://en.wikipedia.org/wiki/Wikipedia:Signs_of_AI_writing) — Wikipedia's comprehensive editor guide for identifying AI-generated content, covering content, language, style, formatting, and citation patterns.
- [GitHub Gist — AI Writing Tropes to Avoid](https://gist.github.com/ossa-ma/f3baa9d25154c33095e22272c631f5a1) — The tropes.fyi list in a format suitable for inclusion in AI system prompts.

### Practitioner analysis

- [Colin Gorrie — Why ChatGPT writes like that](https://www.deadlanguagesociety.com/p/rhetorical-analysis-ai) — Rhetorical analysis identifying compulsive parallelism, explicit antithesis, and device saturation as key AI tells.
- [Beutler Ink — How to Spot AI Writing](https://www.beutlerink.com/blog/how-to-spot-ai-writing) — Identifies negative parallelism ("It's not X — it's Y") as the most recognizable AI tell, plus false ranges, compulsive summaries, and formatting overkill.
- [Charlie Guo — The Field Guide to AI Slop](https://www.ignorance.ai/p/the-field-guide-to-ai-slop) — Categorizes AI patterns from red herrings (unreliable indicators) through stylistic tics, structural patterns, and uncanny content.
- [Michelle Kassorla — Recognizing AI Structures in Writing](https://michellekassorla.substack.com/p/recognizing-ai-structures-in-writing) — Focuses on sentence-level structural patterns: simple sentence chaining, semicolon connectors, and syntactic monotony.
- [Pangram Labs — Comprehensive Guide to Spotting AI Writing Patterns](https://www.pangram.com/blog/comprehensive-guide-to-spotting-ai-writing-patterns) — Extensive taxonomy covering vocabulary, phrasing, grammar, organization, tone, specificity, and repetition patterns.
- [Hana La Rock — 10 Common ChatGPT-isms](https://www.hanalarockwriting.com/post/10-common-chatgpt-isms-what-to-watch-out-for-when-writing-content-with-ai-infographics) — Identifies unnecessary inline definitions, sequencing markers, and excessive qualifiers as key AI tells.
- [Jordan Gibbs — Spot The Bot: Why ChatGPT's Style Is So Obvious](https://medium.com/@jordan_gibbs/spot-the-bot-why-chatgpts-style-is-so-obvious-e27c6afe1595) — Analysis of 15,000 sentences across 27 stylistic dimensions; documents the RLHF origin of ChatGPT's vocabulary preferences.

### Commit message research

- [Fingerprinting AI Coding Agents on GitHub](https://arxiv.org/abs/2601.17406) (MSR, 2026) — Analyzes 33,580 PRs from five AI agents; achieves 97.2% F1-score identifying which agent wrote a PR, with commit message characteristics (multiline ratio, message length) as dominant features.
- [Analyzing Message-Code Inconsistency in AI Coding Agent-Authored Pull Requests](https://arxiv.org/abs/2601.04886) (arXiv, 2025) — Finds 1.7% of 23,247 agentic PRs have high message-code inconsistency; 45.4% of inconsistencies are "descriptions claim unimplemented changes."
- [Lore: Repurposing Git Commit Messages as a Structured Knowledge Protocol](https://arxiv.org/abs/2603.15566) (arXiv, 2026) — Introduces the "Decision Shadow" concept: AI commit tools describe what changed, not why, producing "lossy compression of information already present."
- [An Empirical Study on Commit Message Generation using LLMs](https://arxiv.org/abs/2502.18904) (ICSE, 2025) — Evaluators preferred LLM-generated messages over human ones, favoring human messages only 13.1% of the time. Traditional metrics (BLEU, ROUGE-L) correlate poorly with human judgment.
- [The Emoji Commit Index](https://www.allstacks.com/blog/the-emoji-commit-index) (Allstacks, 2025) — Documents emoji adoption in commits jumping from ~25% to ~75% of organizations in 2023–2025, driven by AI commit tools.
- [peakoss/anti-slop](https://github.com/peakoss/anti-slop) (GitHub Action) — 31 checks derived from 130+ manually reviewed AI slop PRs on large open source projects; enforces max commit message length, max emoji count, and max code references.

<!-- vale on -->

## AI disclosure

Claude wrote the majority of rule definitions, documentation, and test cases in this repository. ChatGPT and Gemini generated text samples for cross-model validation. A human designed the rule categories, severity assignments, quality criteria, and the research-to-rule pipeline. A human validated each AI-generated rule against test documents containing known patterns.

The CITATION.cff lists the human author. It omits AI tools, consistent with [Committee for Publication Ethics (COPE) guidance](https://publicationethics.org/guidance/cope-position/authorship-and-ai-tools) on AI and authorship.

## Citation

If you use this package in research or want to cite it, see [`CITATION.cff`](CITATION.cff) for the citation metadata.

## License

MIT
