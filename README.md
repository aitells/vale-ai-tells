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

Packages = ai-tells, \
  https://github.com/tbhb/vale-ai-tells/releases/download/v1.34.0/ai-tells-commits.zip

[*.md]
BasedOnStyles = ai-tells
```

Then run:

```bash
vale sync
```

The bare `ai-tells` name works because [Vale's package catalog](https://vale.sh/explorer) lists the style and points that name at the latest release. Name a release URL instead to pin a version. The `ai-tells-commits` style is not in the catalog, so it installs by URL either way.

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
| `CommitFigurativeVerbs` | Figurative verbs with an inanimate subject, drawn from commit messages a maintainer rejected: a fix that "arrived," a setting that "carries" a value, a file that "survives" a rebase, a gate that "demands" a clean run, a config that "lives in" a manifest, a message that was "hand-edited." Lives in the commit style rather than the prose style because the subject-plus-verb token floods ordinary technical writing, where a table really does hold values. |
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

This package contains 133 rule files covering different categories of AI tells. All rules default to `error` level.

<!-- vale off -->

| Rule | Description |
|------|-------------|
| `AbsoluteAssertions` | AI overconfidence: "the only way to," "the only real solution," "make no mistake," "there is no denying," "above all else," etc. Verify the claim or soften it. |
| `AIAdjectiveNounPairs` | AI adjective immediately preceding a noun: "holistic approach," "seamless integration," "transformative impact," etc. |
| `AICompoundPhrases` | Compound phrases: "rich tapestry," "intricate interplay," "paradigm shift," "double-edged sword," "moving the needle," "unlocks new," etc. |
| `AnnouncementHeadings` | Headings that narrate content rather than being it: "What You'll Learn," "What We'll Cover," "What to Expect," "Here's What You'll Get," etc. |
| `AnthropomorphicCognition` | Cognition and volition handed to an artifact: a spec that "wants" a retry, a release that "teaches" a skill, a dictionary that "learns" a word, a manager that "knows nothing about" a path, a script that "asks whether," a reviewer's tool that "trusts" its inputs, a parser that "gets confused," a workflow that "misbehaves," text "telling the truth." Also, from a documentation-corpus audit, the judgment verbs behind the same determiner-gated subject ("a record's bytes decide which extractor runs," "the library decides for itself," "prose answers questions," "determinism forbids a model," "the ensemble arbitrates," "a signal that cedes recall," "the create arm adopts an issue"), the fallible artifact ("the loader could mistake X for Y," "one scan can't prove," "the parser guesses"), the artifact that asks for, hunts, or pretends, the failure text that "tells you to" refresh, the ditransitive teacher ("would teach a reviewer the wrong contract"), and transitive "confuse" ("characters that confuse tokenization"). The wanting token is determiner-gated with human subjects excepted, so "the user wants a report" stays quiet; bare "behave" and "objects" as a verb stay out on corpus and homograph grounds, and "refuses" stays out as the plain verb for a check that rejects its input. Disable the rule for prose about people, and for machine-learning writing, where a model literally learns. |
| `AnthropomorphicJustification` | Treating abstractions like employees: "does the heavy lifting," "pulls its weight," "pays for itself," "speaks for itself," "load-bearing," "does the real work," etc. Also coronation ("crowns the release," "crowning achievement"), rank-claiming ("claims the top spot"), and agency verbs ("behaves itself," "pretends otherwise," "cares deeply," "forms an opinion," "delivers on its promise," "hangs on a single assumption," "hinges on whether," reflexive "the query narrows itself," "the config tunes itself," the self-report "declares itself," "announces itself," "proves itself," and the voice figure "speaks up"). Also the adjudication family, where a fact gets the gavel: "the benchmark decides the debate," "latency puts the matter to rest," "lays the issue to rest." The settle tokens ("availability settles the question," "the reconfirmation settles it") live in `FigurativeSettles`, the invoice tokens ("the run settled the cost," "squares the ledger," "settles up," "balances the books") live in `FigurativePays`, and every form of "earn" lives in `FigurativeEarns`. |
| `AnthropomorphicAdjectives` | Character grades applied to a mechanism: a default that is "benign," a test that is "brittle," a heap target that is "noisy," a timeout that is "generous," a cache that "stays healthy," a claim that is "honest about its limits." `AnthropomorphicJustification` reads the merit verbs; this reads the adjectives, which a documentation-corpus census found to be a class of their own. An attributive token gated on a determiner, refusing the heads that take the adjective literally (a person, a tumor, a tip, a room), and a predicative token gated on a copula, with "honest" only there since `EnforcementMetaphors` reads the honest count and the check that keeps something honest. "Naive," "aggressive," "conservative," "expensive," "fragile," "greedy," "smart," "graceful," "elegant," and "happy" measured out as the corpora's own vocabulary or as other rules' words. The six kept match fourteen times across the pre-LLM corpora ("generous upper limit," "noisy heap target," "brittle workarounds," "benign snippet"), each the figure, flagged on the maintainer's call. Disable the rule for medical or community writing. |
| `AbstractionSubject` | The anaphoric abstraction subject, the prior sentence compressed into an abstract noun with a demonstrative on it and that noun made the subject of a comment: "That asymmetry is the point," "This inversion buys the reverse lookup," "That gap is where the second read happens," "This separation is deliberate," "That symmetry is not an accident," "This coupling is the price." The plain form names the thing and says what it does ("The reverse lookup costs one read"). `Metacommentary` keeps the bare "matters" verdict and the "means" spelling, and `MicDrop` keeps the demonstrative verdict; this rule takes the abstraction noun ahead of any other verb of comment and ahead of the copula. A passive after the copula stays quiet as docs English ("That constraint is enforced by the database"), so does a measurement ("That gap is 4 bytes"), and lowercase "that" never fires because in the pre-LLM corpora it always opens a clause. The kept tokens match three times across the Go and Python standard libraries, each the construction itself. |
| `AffirmativeFormulas` | Revelation patterns: "Here's the thing," "And that's the beauty of it," "Let that sink in," etc. |
| `CataphoricForecasting` | Numbered lead-ins that announce a count of items and then enumerate them: "Three pillars support this strategy," "Four user journeys define the experience," "Here are the four options," "There are three reasons this matters," etc. Anchored to a sentence-initial capitalized cardinal, so mid-sentence counts ("all three files," "about five minutes") stay clean. The forecasting-verb token can fire on a literal count subject ("Four wheels drive the axle") and a few scaffold nouns have literal senses ("Three levers control the press"); disable the rule for mechanical or hardware writing. Vale cannot confirm a list actually follows, so sentence-initial position is the proxy for the adjacency. Also the bare sentence- or heading-initial count with no curated noun or verb ("The three axes," "Eight repos seed the list," title-case "Three Layers Guard an EDA") and the folksy proportion ("three of every four runs," "nine times out of ten"). Temporal openers ("Three years ago," "The two weeks of onboarding") stay clean, but a plain count subject fires ("Five people attended") and so does a cardinal-led proper noun ("Three Mile Island"); disable per-file where counts are data or add project exceptions. |
| `ClosingPleasantries` | Sign-off language: "I hope this helps," "Feel free to ask," "Don't hesitate to reach out," etc. |
| `ColloquialAssessments` | Knowing-tone verdicts: "the joke lands," "really lands," "X is the move," "that's the move," "what really matters," "all that matters," and the folksy usefulness grade "handy for," "comes in handy." |
| `ColonUsage` | A capitalized word after a colon, the "Label: Sentence" construction ("The takeaway: Always test."). Replaces `Google.Colons`, which also lints heading text and flags the title half of "Appendix A: Glossary"; headings are exempt here. Acronyms, the pronoun "I," quotations, and clock times stay clean. Vale strips markup before matching, so run-in bold labels ("**Example:** Like this.") still flag; disable the rule where that convention is established. |
| `ConclusionMarkers` | Formulaic conclusions: "In conclusion," "Ultimately," "At the end of the day," etc. |
| `ConsequenceClause` | The mechanism-and-inference sentence: a clause states what something does, then ", so" introduces a second clause with a fresh full-noun subject and its own present-tense verb that draws the conclusion for the reader ("a replay checks out every commit it moves, so the sandbox deny applies to a staged change too," "the styles ship as release assets, so the version pins itself"). Human prose follows ", so" with a pronoun or "so that"; the gate is the determiner, a noun phrase of up to three words, and a verb that is not a copula or a modal, so "so the order doesn't matter" and "so you can rebase" stay out. Fifty-eight hits across the seven pre-LLM corpora, each the construction, at 0.3 per ten thousand words or less against about six in agent-written documentation. Split the sentence and state the effect as its own claim. |
| `ConsequenceParticiple` | The consequence tail, "which means" with the "which means" deleted: a clause ends, then a comma and a present participle restate its effect. "The sweeper drops the row, leaving the cache cold," "rebuilds the index on every write, making every read a miss," "giving the caller one row per blob," "meaning the index is stale," "letting the reader skip the scan," "forcing a second pass," "resulting in a deadlock." The plain form ends the sentence and states the effect as its own claim. The gate is the participle plus a determiner, pronoun, or quantifier, so "making sure," "leaving aside," "giving up," "meaning of," and "making it possible" stay quiet; `ParticipialPadding` keeps the press-release lexicon. The kept participles match about a hundred times across the Go and Python standard libraries, each the construction itself, "making" and "meaning" a third each; "allowing," "causing," and "creating" stay out as the ordinary docs spelling of a side effect. |
| `ContrastiveFormulas` | Rhetorical contrasts: "It's not just X; it's Y," "These aren't X. They're Y," "This doesn't mean X. It means Y," "The real question isn't X; it's Y," "Not only X but also Y," etc. Also the bare appositive "a refinement, not a rivalry," which needs no verb and so fires in headings too. |
| `ContrastiveNegation` | Telegraphic negation cadence that replaces the "not X; it's Y" formula once it gets flagged: stacked "no setup, no config, no hassle" and the single clause-final fragment "cleartext repo names, no k-anonymity gate." Aggressive; it can fire on "coffee, no sugar," so disable it for terse spec lists. |
| `CoordinatedReveal` | The reveal by quantifier, the "not X, it's Y" pivot with the negation deleted: a claim stated once, then ", and" and the same claim again with a totality word doing the turn. "That join reverses, and a chunk maps back to every blob that contains it," "append-only, and a blob's bytes never change," "and only the sweeper," "and nothing else has it," "each caller that reads them." |
| `DefensiveHedges` | Preemptive concessions: "This may seem X, but..." "Admittedly, X, but..." "At first glance," etc. |
| `DespiteChallenges` | The "despite challenges" dismissal formula: "despite these challenges," "while challenges remain," "challenges notwithstanding," etc. |
| `DoubleHyphen` | A literal double hyphen, the ASCII stand-in AI types when it cannot produce an em dash. Split from `EmDashUsage` so the fix can differ: backtick it as a CLI flag or literal, or use a real em dash character for punctuation. |
| `EmDashUsage` | Em-dashes, which AI uses excessively |
| `EmphaticCopula` | Italicized copula verbs, determiners, and intensifiers for manufactured profundity |
| `EmptyPadding` | Empty modifiers before a noun the noun does not need: "various stakeholders," "respective roles," "given task," "particular concerns," etc. Sequence-based (modifier plus noun), so it casts a wide net and flags literal uses too ("various reasons," "a certain amount"). Deliberately broad; suppress per-section or disable where the literal sense is common. "Named" moved to `NamedAdjective`, which gates it on the definite determiner and keeps "a named pipe" quiet. |
| `EmptyPaddingStacked` | The same empty modifiers with an adjective ahead of the noun: "certain strategic concerns," "various regional teams," etc. A three-token companion to `EmptyPadding` for the modifier-adjective-noun construction, since Vale sequences cannot make the adjective slot optional. Same breadth and the same suppression advice. |
| `EnforcementMetaphors` | A check presented as a sentry: a guard that "stands down," a gate left "armed," a linter that "keeps its teeth" or turns "toothless," a workflow that "polices" an arrangement, a formatter that would "fight" the installer, gates that "keep them honest," a grant with no fingerprint "standing behind" it, a skill "standing in the way," "left standing," and a rule that would "flood." Also candor credited to a number ("an honest count," "keeps a before-and-after comparison honest," "the honest decode") and gating as a verb ("the root that gates it," "the live roots gate every table," "to gate a security control"), which matches eight times in Go comments ("this gates the experiment") and disables for feature-flag prose that has settled on the verb. Timer arming and literal teeth stay quiet; disable the rule for security or law-enforcement writing. The same census added the setting in office ("the flag governs whether the cache writes," "rules that govern how the tag resolves") and the failure climbing the chain of command ("a warning escalates to an error"), four and five hits across the pre-LLM corpora, the PEPs and Rust RFCs writing both of their own committees. |
| `EvasionMetaphors` | A miss framed as an escape: a defect that "slipped through" or "slips past," a filter that "let it through," "lets violations into production," or "lets a stale row past," a rule people "route around" or "go around," a change that "snuck past" or "sidesteps" a guard, a gap that "went unnoticed" or "goes unreported." "Dodges" and "sails through" stay in `FigurativeIdioms`; disable the rule for clothing, mechanics, or networking prose, where things literally slip and traffic is literally routed around damage. |
| `ExplainerHeadings` | Tutorial-blog heading clichés: "Deep Dive," "Under the Hood," "Demystifying X," "Why It Matters," "A Closer Look," etc. Also the general free-relative heading, a wh-word plus a determiner-gated subject and verb: "Why the Pin Exists," "How the Cache Works," "What the Data Shows." Conventional doc headings ("How to Configure X," "What's New") stay out. |
| `ExplainerLeads` | The same free relative used as a framing device in prose: the cleft lead-in ("Here's what the change does," "This is why the pin matters"), the label before a colon ("What the hook does: it refuses the write"), and the sentence-initial pseudo-cleft ("What the hook does is refuse the write"). Embedded clauses doing real work mid-sentence ("depends on how the shell resolves it") stay out. |
| `FalseBalance` | Evasive "both sides" language: "both sides present valid points," "nuanced approach," etc. |
| `FalseExclusivity` | False insider drama: "nobody talks about," "what most people miss," "the dirty secret," "the elephant in the room," etc. |
| `FigurativeFalls` | "Falls" as an overused verb for shortcoming, membership, and neglect: a result that "falls short," a design that "falls apart," a case that "falls under" a category or "falls within scope," a task that "falls by the wayside" or "through the cracks," a request that "falls on deaf ears," responsibility that "falls to" a team, the past tenses ("fell short," "had fallen behind"), the bare category sort ("falls into one of three dispositions"), the bounded placement ("falls within the window"), and the numeric floor ("fell under the floor"). Gated on the figurative complement, so literal falling (prices, temperature, night, rain) stays quiet; disable the rule for gravity or weather writing. "Falls back to" stays out with 219 pre-LLM corpus hits as the plain name for a second choice. "Fell into place" stays in `NarrativePivots`, and "falls into three categories" stays in `CataphoricForecasting`. |
| `FigurativeHolds` | "Holds" as an overused possession verb for abstractions: a chart that "holds the same wide spread," a result that "holds across datasets," a claim that "holds up under scrutiny," an approach that "holds great promise," "the correlation still holds." Gated on the figurative complement or a curated abstract subject, so literal holding (hands, jars, court sessions) stays quiet; disable the rule for legal or wrestling writing. "Holds its own" stays in `AnthropomorphicJustification`, and the bare container sense ("the table holds every row") is `BareHolds`. |
| `BareHolds` | The bare possession verb, a data structure with hands: "the table holds every stage's tables," "two records hold identical bytes," "the column holds the serialized object," "whatever the store holds," "the counts the aux tables already hold," "code held as a config value," "a directory holding one." The plain verb is "contains," "stores," or "has." An open determiner-gated subject with the object inside the span, so the exceptions can name the concurrency register (a goroutine holds the lock, a caller holds a reference) and the physical world (a hand, a jar, a clamp). Split from `FigurativeHolds` because the count is large: about 160 hits across the Go and Python standard libraries, the container idiom of pre-LLM programming prose, every one the substitution this rule names and flagged on the maintainer's call. The loudest rule in the package on ordinary technical writing; a project that keeps the container sense disables it per file. |
| `FigurativeIdioms` | Fixed figurative phrases standing in for a plain statement of what happened: "costs little," "fares no better," "out of reach," "for want of," "empty slate," "dodges the rule," plus the consequence metaphors "where this bites," "sails through," "moving the goalposts," and "blast radius," the reduction idioms "comes down to" and "boils down to," the unpriced tradeoff "comes at a cost" (the named spelling "at the cost of performance" stays quiet), the audit formulas "measured cost" and "what remains of" ("what remains is" and "what remains after" stay quiet), the accepted invoice "the cost the rule already accepts," "accepts a small cost," and "tolerated cost," and the substitution verb "stands in for." Another group comes from a retroactive commit-history audit: "closes the gap," "in lockstep," "point of no return," "under its own power," "covers more ground," "brings into line," walking a decision back, main "moving under" a branch, the dogfooding family ("eats its own cooking," "dogfoods," "drinks its own champagne"), "sleeping dogs," and a query or release that "fans out," with the concurrency nouns "fan-out" and "fan-in" left alone. A third group comes from a documentation-corpus audit: "lines up with," "doubles as," "double duty," "the whole trick," "a step further," "meets that bar," "on hand," "went missing," "went away," "for good" ("for good measure" stays quiet), "made that call" ("made the call" stays out as a function call), "judgment call," "takes a while," "gets it backwards," "picks up on," "from two angles," and "stands up a service." "Survives the rebase untouched" moved to `MortalityMetaphors`. Whole idioms rather than a gated verb, so no subject gate is needed; disable for runtime and memory-management prose, where a value is literally out of reach, and for placeholder-heavy API prose, where a test double literally stands in for the real thing. Burial joins the list after a documentation-corpus census ("buried in the config," "buried deep in the log," "buries the error"), five pre-LLM corpus hits, each the figure. |
| `FigurativeQuantities` | Quantity expressed through a physical metaphor instead of a number: the body-part and kitchen dodges for "a few" ("a handful of tests," "a smattering of users," "a sliver of," "a dash of," "a pinch of"), the crowd nouns standing in for "many" ("a slew of," "a host of," "a raft of," "a spate of," "a flurry of," "a litany of," "a laundry list of"), container and landform scale ("a boatload of," "a ton of," "a heap of," "a pile of," "a mountain of"), weather and water scale ("a sea of," "a flood of," "a wave of," "a deluge of," "an avalanche of"), the fancy vague quantities "a myriad of," "a plethora of," "a wealth of," and "a trove of" (the first three migrated from `FillerPhrases`), the mixture metaphors ("a smorgasbord of," "a patchwork of," "a mosaic of," "a constellation of"), "array" only when an adjective inflates it ("a vast array of"), and distance standing in for a count ("how far one label reaches," "how far these numbers travel"). Each phrase is what a model reaches for when told to remove one of the others, so the whole substitution pool shares one rule and one message. The bare noun "array" stays uncovered as literal everywhere in technical prose; disable the rule for memory-management prose, where objects really do live on a heap, and for networking prose about hosts. |
| `FigurativeDisguises` | The disguise frame, the sibling of the substitution verb in `FigurativeIdioms`: an opinion "disguised as" a question, complexity "masquerading as" rigor, a rewrite "dressed up as" a refactor, a fix "parading as" a feature, an ad "posing as" a review, a form "pretending to be" a conversation, "what passes for" documentation, a wrapper that "passes itself off as" the original, a spreadsheet "cosplaying as" a database, plus the noun forms "in disguise," "under the guise of," "in sheep's clothing," and the stacked impostors "in a trench coat." The verbs match inflected forms only, so the noun homographs (a party disguise, a masquerade ball, a parade route, salad dressing) stay quiet; the comparison construction ("poses as much risk as it removes"), the mathematical "posed as," the bare "passes for the wrong reason," and the literal impersonation of the Windows security API all stay uncovered. Disable the rule for security or forensics prose, where malware really is disguised as an invoice, for emulation and test-double prose, where a mock is built to pretend, and for costume writing. |
| `FigurativeLands` | "Lands" as an overused arrival verb: "the request lands on the node," "the PR lands in main," "where the idea lands." Also catches the prepositionless arrival after a temporal or conditional subordinator ("once the feature lands," "when the PR lands," "until the fix lands"), the perfect and adverbial arrival ("the fix has finally landed," "support landed upstream," "lands as a single commit"), the bare arrival at a clause boundary ("once merged, the fix lands."), and the transitive landing ("landed a fix," "landing it means"). Exempts common literal landers (a plane, a bird, a probe) and the achievement and athletic idioms ("landed a job," "lands the jump"); rare ones fire, so disable the rule for aviation or nature writing. |
| `FigurativeCarries` | "Carries" as an overused freighting verb: a term that "carries baggage," a change that "carries significant risk," an approach that "carries a caveat," one test that "carries the suite," and an inanimate component treated as a vessel for abstract cargo ("the daemon carries no pipeline logic," "the packet carries the payload," "the signal carries data"), or as the bearer of a policy rather than the place it is written ("the lower block carries the pattern," "the config carries the exemption"). Also the typographic cargo ("carries a repotools prefix," "carries a suffix"), the negation whatever the object ("it carries no counts and no dates," "carries zero overhead"), the mirrored possession ("carries the same caveat"), and an open determiner-gated subject with the common literal carriers (trucks, couriers, viruses, wires, Go's own Context) listed as exceptions, so "the manifest carries the pin" fires whatever the complement, along with the bare "carry" a plural subject or relative pronoun proves is the verb ("the machine formats carry the score columns," "the blobs that carry no state rows"). The phrasal "carries out" (execute) and "carried over" (bring forward) stay quiet, and the arithmetic carry noun never matches; disable the rule for freight, logistics, biology, electrical, or arithmetic writing. "Carries its weight" stays in `AnthropomorphicJustification`. |
| `FigurativeRides` | "Rides" as an overused dependence verb: "everything rides on this migration," a fix that "rides along" in a release or "rides alongside" a bump, an edit that "rides through" on an exemption, a cache that "rides on top of" Redis, a launch "riding the wave," and an operation treated as a passenger on the infrastructure it uses ("the query rides the index," "the lookup rides the cache"). Gated on the figurative complement, so literal riding (buses, horses) stays quiet; disable the rule for transit or equestrian writing. The mechanism list takes "the chain" after a documentation-corpus census ("the lookup rides the chain"), which measures zero across the pre-LLM corpora. |
| `FigurativeQuiet` | "Quiet" as an overused word for personified inaction: a check that "stays quiet" or "stays silent," a log that "goes quiet," a handler that "quietly drops" the error, "quietly ships," "quietly falls back," a mechanism that "keeps the console quiet." Gated on the construction (an inanimate subject going silent, or "quietly" ahead of an action verb), so literal quiet (a room, a person, the `quiet` flag) stays quiet; disable the rule for prose about sound. The verb joins the adjective after a documentation-corpus census: a check muted rather than turned off ("the flag silences the warning," "silenced every alert"), nine pre-LLM corpus hits, mostly the Rust RFCs and Python sources writing "silence the lint," each the figure. |
| `FigurativeLoud` | The mirror of `FigurativeQuiet`: "loud" as an overused word for personified emphasis. A check that "fails loudly," a linter that "loudly complains," a metric that "sends a loud signal," a warning that comes through "loud and clear." Gated on the construction ("loudly" ahead of an action verb, or an emphasis idiom), so literal loudness (a room, music, a noise) and bare "out loud" (reading, thinking) stay quiet; disable the rule for prose about sound. |
| `FigurativeRuns` | "Runs" gated hard on figurative complements, since software literally runs everywhere: "runs deep," "runs counter to," "runs the gamut," "runs the risk of," "runs circles around," "ran its course," "running on fumes," "hit the ground running," and the pervasion construction ("one limit runs under the whole table," "a theme runs through the essay"). Everyday literal senses ("run the tests," "the server runs on port 8080," "up and running") never match; disable the rule for athletics or plumbing writing. "Run a tight ship" stays in `ShipOveruse`. |
| `FigurativeWins` | "Wins" as an overused verb framing a choice as a contest: an approach that "wins the day," a design that "wins out," a refactor that is "a quick win," "a winning combination," "for the win," and, after a documentation-corpus audit, the contest with an inanimate subject ("a lower index wins," "one item per group wins as primary," "which source won," "losers then split," "picking a winner," "outranks," "beats an explicit flag") and the starting whistle "kicks off." The precedence sense ("last write wins") now fires on the maintainer's call, with twenty-four pre-LLM corpus hits, and "kicks off" at the same count; state the rule that picks instead. The beings who literally win (a team, a candidate, a player) sit in the exceptions, "races" and "dominates" stay out as the data race and the dominator tree; disable the rule for sports or gaming writing. |
| `FigurativeSits` | "Sits" as an overused placement verb: "sits at the intersection of," "sits alongside," responsibility that "sits with" a team, work that "sits idle." Mostly gated on the figurative complement, so literal sitting stays quiet. One token gates on the subject instead, catching a document or config element placed by "sits" where "is" would do ("the entry sits in the config block," "an orphan row sits on a record"), with companions for the pronoun subject ("these sit ahead of the subcommand name"), the inverted order ("over each column sits an index," "beside it sit flat columns"), and the posture complement ("sits quoted and escaped," "sits outside every fence"); disable the rule for furniture, cartography, page-layout, or memory-layout writing. |
| `FigurativeStrikes` | "Strikes" as an overused verb for resonance and aptness: an argument that "strikes a chord," a critique that "strikes at the core of" the design, a phrase that "strikes the right tone," a rewrite that "struck gold." Gated on the figurative complement, so literal striking (a match, lightning, a labor strike) stays quiet; disable the rule for labor or percussion writing. "Strike a balance" stays in `FalseBalance` and "at the heart of" stays in `PromotionalPuffery`. |
| `FigurativeLends` | "Lends" as an overused verb for conferring an abstract quality: a structure that "lends itself to" reuse, a study that "lends credence," a detail that "lends weight." Gated on the figurative complement, so literal lending (money, a book) stays quiet; disable the rule for library or finance writing. |
| `FigurativeDraws` | "Draws" as an overused verb for sourcing and comparison: an argument that "draws on" prior work, a section that "draws a distinction," a heading that "draws attention to" a caveat, a post that "draws to a close." Gated on the figurative complement, so literal drawing (a card, water, a weapon, blood) stays quiet; disable the rule for art or card-game writing. |
| `FigurativeCasts` | "Casts" as an overused verb for projecting an abstraction: a finding that "casts doubt on" a result, a decision that "casts a long shadow," a rewrite that "casts a wide net." Gated on the figurative complement, so literal casting (a fishing line, metal, a vote, actors) stays quiet; disable the rule for fishing, metalwork, or theater writing. |
| `FigurativeClears` | "Clears" as passing described as a jump: a draft that "clears the gate," a message that "cleared every check," a fix "clearing a finding," a branch that "clears CI," and the bound and pass nouns that stand in for a check ("clears the target," "the blobs that cleared the run"), plus the intransitive "clears on the next run." Gated on the checking noun after the verb, so clearing a cache or a screen stays quiet, and the pronoun object ("clears it") stays out as the deletion sense; disable the rule for athletics writing, and for interface prose where clearing an alert means dismissing it. |
| `FigurativeFires` | "Fires" as an overused verb for a check doing its job: a rule that "fires," hooks that "fire on every commit," an alert that "never fires," the pronoun subject carried over from the previous sentence ("they fire nothing," "so it fires nothing"), and "misfires." Gated on a checking-or-alerting subject, so the timers and events pre-LLM systems prose gives this verb ("the timer fired," "the event fires") stay quiet, along with guns and kilns; the pronoun token cannot see a timer subject, so timer prose disables the rule, as do firearms or ceramics writing. |
| `FigurativeTrips` | "Trips" as an overused verb for setting off a check: prose that "trips the rule," a flag that "trips the linter," writing that "still trips it." Gated on the checking object, so "round-trip a string," "trip the detector," and "trip the barrier" (established systems usage) stay quiet; disable the rule for electrical or hiking writing. |
| `FigurativeSees` | "Sees" as an overused witness verb: a library that "sees heavy use," an endpoint that "saw a spike in errors," a year that "saw the introduction of" a feature, a project that "has seen its fair share." Gated on the complement, so literal seeing stays quiet; disable the rule for prose about eyesight. "Never sees" stays in `CommitFigurativeVerbs`. |
| `FigurativeTravels` | "Travels" as an overused journey verb for transmission: a request that "travels through the stack," data that "travels," "the precomputed digests travel into that bundle," "that identifier travels with the record," a pattern that "travels well." An open determiner-gated subject with a widened destination set, since the curated data-noun list leaked on every noun outside it; the open token still measures zero across the pre-LLM corpora. Literal travel (a family, light) is the disable-in-domain register; disable the rule for transit or physics writing. |
| `FigurativeBreeds` | "Breeds" as causation given a biological verb: complexity that "breeds confusion," inconsistency that "breeds distrust," "a breeding ground for" bugs. Gated on the abstract offspring, so literal breeding (dogs, livestock, mosquitoes) stays quiet; disable the rule for husbandry or biology writing. |
| `FigurativeDemands` | "Demands" as obligation issued by an abstraction: a migration that "demands care," an edge case that "demands attention," an interface that "demands a closer look." Gated on the complement, so a person demanding a refund and the economics noun stay quiet; disable the rule for labor or economics writing. The determiner-gated bare construction ("the gate demands a clean run") stays in `CommitFigurativeVerbs`. |
| `FigurativeLives` | "Lives" as location by residence: config that "lives in" a file, logic that "lives upstream," truth that "lives in one place," "where the exemption lives." An open determiner-gated subject with the beings that literally reside (families, species, neighbors) listed as exceptions, so the residence figure fires whatever the artifact, plus the bare-noun subject ("Free-block bloat lives in the file layout," "operator mechanics live elsewhere") and the "as" complement ("that split lives as reviewed data"); the pre-LLM programmer idiom ("the package lives in," "code lives in cmd/link") fires by design, while "this lives in" and the compiler's liveness vocabulary ("variables live at block entry") stay out. Disable the rule for biography or housing writing. |
| `FigurativeOwns` | "Owns" as responsibility by possession: a tool that "owns" a directory, a rule that "owns" a phrase, an installer that "owns" the deployed tree, "the owning rule," and the component that owns the table it writes ("the table it owns," "it owns three tables," "the columns each stage owns," "the docs that own the decision cut," "no owning component," "the grading pass owns where the signal applies"). The concurrency and memory register (a goroutine owns a lock, a caller owns a buffer) and legal ownership (copyright, trademarks) sit in the exceptions; disable the rule for prose about resource lifetimes. |
| `FigurativeSettles` | The settlement figure: a dispute closed, dust coming to rest, a form hardening into permanence. The gavel moved from `AnthropomorphicJustification` ("availability settles the question," "the reconfirmation settles it," "a classifier settles those"), the dust idiom ("once the dust settles," "wait for the dust to settle"), settling into stability ("the API settled into its final form," "settled into a rhythm," "settled into place"), the closed question ("the debate is settled," "consider it settled," "settled law," "far from settled"), and the score ("settles an old score with the flaky suite"). The choice senses ("settled on a heuristic," "settle for the simpler form"), "settle ties," settlers and settlements, dust landing on a surface, and the convergence register ("the pacer settles into a steady state") all stay quiet; disable the rule for legal or geology writing, where parties literally settle disputes and dust literally settles. The invoice tokens ("settled the cost," "settles up") stay in `FigurativePays`, and "fell into place" stays in `NarrativePivots`. |
| `FigurativeStays` | "Stays" as personified restraint: a check that "stays green," a helper that "stays out of the way," a fix that "stays clear of" the hot path, work that "stayed behind" on an assumption, deciding "what stays in and what stays out," and, after a documentation-corpus audit found the curated adjectives leaking on ninety-two others, any state complement behind a determiner-gated subject ("the value stays complete," "each field stays optional," "the index stayed small") plus a grown list for the bare verb ("stays deterministic," "stays put"). The plain word is "remains" or "is." The open token refuses places, times, and a person's condition, so a guest staying at a hotel stays quiet, and "stays in sync" stays out as the corpora's own invariant idiom; disable the rule for lodging or travel writing. "Stays quiet" and "stays silent" stay in `FigurativeQuiet`. |
| `FigurativeSurfaces` | "Surfaces" as discovery by emergence: drift that "surfaces" on a change, an audit that "surfaced a defect," a command that "surfaces skills whose definition matches," "nothing surfaced this earlier," and the bare verb behind a modal or "to" ("tooling to surface changes," "will surface reports," "can surface bugs"). Gated on an open object or a defect-family subject, with the prepositions and copulas that would admit the plural noun refused, so the API surface and the road surface stay quiet; the bare verb fires thirteen times across the pre-LLM corpora, each the figure. The noun ("the prose surface") is `FigurativeNouns`' to read. Disable the rule for marine or graphics writing. |
| `FigurativeSweeps` | "Sweeps" as an overused verb for wholesale motion: a change that "sweeps away" the old behavior, a refactor making "sweeping changes," a problem "swept under the rug," reviewers "swept up in" the excitement, a trend that "swept through" the industry, the bare removal of records ("Sweep the failures," "sweeps every stranded row"), plus the totality idioms "a clean sweep," "in one sweep," and "one fell swoop." Gated on the figurative complement, so the garbage collector's mark-and-sweep of spans, a parameter sweep, and a radar sweep stay quiet, and the audit-pass noun ("a sweep over the docs") stays uncovered as established programmer usage; disable the rule for housekeeping or weather writing, and for collector prose that sweeps dead objects. |
| `FigurativeReaches` | "Reaches for" as selection described as motion: prose that "reaches for the same verb," a rule that "reached for a curated list," AI that "reaches for this structure," writers who "reach for a metaphor," the imperative ("Reach for it in a script," "Reach for a slice when the skip doesn't cover it"), and the second-person or generic-human subject ("you might reach for a git dependency," "users reach for the path form"). An open determiner-gated subject with the beings and limbs that literally reach (hands, children, climbers, robot arms) listed as exceptions, a curated bare-subject token for "AI reaches for," a complement gate on the writing-device nouns whatever the subject, a sentence-start gate for the imperative, and a subject list for the human subjects. The imperative measures zero across the pre-LLM corpora; the human-subject token fires five times, four Rust RFCs and one Go comment making the same selection figure, flagged on the maintainer's call. "Out of reach" stays in `FigurativeIdioms`, "reach out" in `ClosingPleasantries`, the arrival sense ("the record reaches the store") in `BareReaches`, and the noun ("its primary reach") in `FigurativeNouns`; disable the rule for sports or robotics writing. |
| `BareReaches` | The bare arrival verb with an inanimate subject: "only referenced records reach the store," "an orphan never reaches an extractor," "the stage hasn't reached that record yet," "confirm the catalog reached the store," "a fragment reaches nothing," "the items a query reaches." The plain sentence names the step that handles the record or where it is sent. An open determiner-gated subject with a bare plural, the perfect tenses, and the clause-final relative clause as companions; the beings, vehicles, and physics that literally arrive sit in the exceptions, and the measurement senses ("reaches zero," "reaches EOF," "reaches the end," "reaches its limit," "the timeout is reached") stay quiet. Split from `FigurativeReaches` because the count is high: about fifty hits across the pre-LLM corpora, the transport idiom of runtime prose, flagged on the maintainer's call. Disable the rule for transit or physics writing. |
| `BareNames` | The designation verb with an inanimate subject: "the manifest names the tag," "the field names the target," "the plain sentence names the step," "a recipe names a gate," "it names a kind of file," "the rejections named figurative language," "an identifier naming an object." The plain verb is "specifies" or "references." An open determiner-gated subject with the pronoun and relative subjects, the bare plural, the modal, and the gerund as companions; the object gates on its own determiner so the plural noun ("the type names that appear") stays quiet, and the people and bodies that literally give or publish a name (a team names a release, a complaint names a defendant) sit in the exceptions. `AnthropomorphicJustification` had left the verb alone because Go and Python documentation use it for what an identifier denotes, and `CommitFigurativeVerbs` covered it only in a commit message; it matches about fifteen times across the two standard libraries, flagged on the maintainer's call. Disable the rule for API reference prose. |
| `NamedAdjective` | "Named" as a pointer adjective: "the named file," "the named recipe," "each named rule," "its named target," the same designation as `BareNames` worn as a modifier. Write the identifier itself, or say which one. Took "named" from `EmptyPadding` and `EmptyPaddingStacked`, whose tagger-driven pair flagged every "named pipe" with an instruction to delete the word. Gated on the definite determiner, so "a named type," "named pipes," and "a named tuple" (a thing that has a name, as opposed to an anonymous one) stay quiet, with a lookahead over the terms of art that keep that sense under "the" too ("the named group"), and the participle ("the file named foo") never puts the adjective beside the determiner; the legal and meteorology terms ("the named party," "the named storm") sit in the exceptions. What matches is the API idiom itself, about 230 times across the Go and Python standard libraries, most of them "the named file" and "the named directory," flagged on the maintainer's call; with `BareHolds` it is one of the loudest rules in the package on reference prose, and a project documenting an API turns it off per file. |
| `FigurativePays` | The transaction figure: effort as spending, benefit as a purchase, consequence as a bill, with the goods left blank. Work that "pays off," a shortcut where you "pay the price," a change that "buys you flexibility" or "buys us time," "the price of admission," "foots the bill," "puts a premium on," "cashes in on." Also the settled invoice, moved from `AnthropomorphicJustification`: a run that "settled the cost" or "settled each token's cost," "settles up," "squares the ledger," "balances the books" (the negotiation sense "settled on a price" stays quiet), and the invoice spelled with "cost" ("never pays that cost," "at no cost," "would pay to compare," "spends work"). Bare "cheap" stays out with fifty-two pre-LLM corpus hits, as a cost the corpora measured. The named tradeoff pre-LLM prose writes ("at the cost of performance," "pay the price of building the map") stays quiet, so only the unpriced transaction fires; disable the rule for finance or commerce writing. "Pays for itself" and "pays dividends" stay in `AnthropomorphicJustification`, and the sentence-final "It pays off." also belongs to `MicDrop`. The count as an invoice joins the family on the maintainer's call: a false-positive tally, a match count, or a line count presented as a price ("costs thirteen corpus hits," "the cost is five hits," "at zero corpus hits," "the cost is real"), which this package's own comments and README rows wrote for years and which measures zero across the seven pre-LLM corpora; the plain sentence says what matched and how often. |
| `FigurativeKeeps` | The upkeep frame, a mechanism credited with keeping something in a state or at a distance: "keeps a re-run cheap," "keeps search fast," "keeps the index small," "kept the output legible," "keeps an orphan away from every extractor," "keeps the rest clear of it," "keeps log lines off the bars," "keeps a reader from mistaking one for the other." The plain sentence says what the mechanism does. The adjective list is the gate, since "keep the buffer small" is ordinary English with most adjectives; the kept ones match seven times across the pre-LLM corpora ("keep the sort result deterministic"). The causative "keeps X from being invoked" and "keeps X out of Y" stay out as the corpora's own "prevents"; "keeps X honest" is `EnforcementMetaphors` and "keeps X quiet" `FigurativeQuiet`. |
| `FigurativeNouns` | Nominalized figuration, which every verb-anchored rule misses: "reach" as a retrieval path ("its primary reach," "per-rule reach," "picks between two reaches"), "wrinkle" as a complication, "story" as a design ("the migration story," "a similar story applies"), "knob" as an option, and "surface" as what a reader sees ("the prose surface," "its canonical surface," "a reader-facing surface"). Each gates on the determiner or compound that makes the noun figurative, at zero to two pre-LLM corpus hits apiece, and the plural "reaches" is admitted only at a clause end or before a copula so "the count reaches 0" stays with the verb. The surface token refuses the exported-names term ("the API surface," "the attack surface") and the physical and linguistic compounds ("surface area," "surface syntax," "the surface language"), and fires seven times in the Rust RFCs and PEPs, five making the same figure and two on the bare "on the surface." "Heartbeat," "waterfall," "gap," and "the poles" stay out as terms of art or too ordinary to gate. Disable the rule for anatomy, textiles, radio, fiction, geometry, or graphics writing. A documentation-corpus census then added "grain" as granularity ("one grain of the analysis," "at a coarser grain"), "lens" as a point of view ("through a security lens"), "headline" as the quoted number ("the headline number"), "cascade" as a chain of consequences ("a cascade of retries"), "dead end," "blind spot," and "seam" as a join between components ("the injection seam"); grain matches seven times across the pre-LLM corpora, the Rust RFCs arguing error recovery "at a coarse grain," and the rest one or two apiece or none, each the figure. "Strata" stays out as the statistics term for a sampling layer. |
| `FigurativeShape` | "Shape" as a stand-in for whichever concrete noun the writer skipped: a data structure, a message format, a review's size, a regular expression, a prose rhythm ("fires on the shape rather than the provenance," "those two numbers pick the review shape," "the rules that shape an analysis," "calls of the same shape," "the wrong shape," "code-shaped"). The most frequent figurative noun in a documentation-corpus census with no rule reading it, and the word this package's own comments and README rows used for every token pattern until the sweep that landed the rule. A determiner-gated noun with an optional modifier, the bare "shape of," the verb in its gerund and relative forms ("shaping the direction of the API," "what shapes the output"), the hyphenated compound past the geometry prefixes, and the gated plural; the sculptor with a determined subject ("the pass shapes the output") stays with `MotionMetaphors`, the modifier slot refuses the Go compiler's "GC shape" and the turtle module's drawn shape, and the trailing check refuses the generics vocabulary ("shape type," "shape instantiation") and the geometric heads ("the shape of the curve"). The count is high and flagged on the maintainer's call: about sixty-five pre-LLM corpus hits, most of them the figure in argument prose ("the particular shape of the parse trees," "the shape of the portable SIMD API") plus the array-dimension term the typing PEPs use ("generic in its shape"). Disable the rule for geometry, graphics, or array-dimension writing. |
| `FigurativeEarns` | Every form of "earn," banned outright: a rule that "earns its keep," a helper that "earns a caveat," a shell that "earns full branch coverage," trust that "is earned," a "well-earned" promotion. The wage figure gets applied to anything at all, so the verb itself is the tell, and the ban covers the literal person-subject uses too by the maintainer's call: the Go standard library never uses the verb, and the Python standard library's only occurrences are one spam-email test fixture. The nominal vocabulary stays quiet ("earnings," "earner," "earnest"); disable the rule for payroll, tax, or finance writing. The earning tokens moved here from `AnthropomorphicJustification`. |
| `FillerIntensifier` | "single" and its cousins riding a determiner that already carries the count: "a single command," "every single time," "no single point of failure," "any single failure," "any one of the checks," "the single source of truth," "a lone exception," "its sole purpose," "a mere formality," "one solitary warning," "a singular focus." Deliberately broad: "no single component owns this" is flagged too, and recasting it takes more than deletion. Hyphenated compounds ("a single-threaded server"), grammar's "the singular form," pronoun heads ("no one," "each one," "every one"), and `AbsoluteAssertions`' "the single most important" stay out. |
| `FillerPhrases` | Padding and performative sincerity: "a wide range of," "in order to," "honestly," "to be perfectly honest," "the honest truth," etc. |
| `FormalRegister` | Overly formal vocabulary: "utilize," "facilitate," "commence," etc. |
| `FormalTransitions` | Formal transitions: "Moreover," "Furthermore," "What's more," "Case in point," etc. |
| `GrowthMetaphors` | The startup-as-organism register: "incubate," "gestate," "nascent," "fledgling," "embryonic," "cultivate," "nurture," "in its infancy," plus scoped startup phrases ("minimum viable," "seed funding," "organic growth"). Disable for medical, nature, or agricultural writing. |
| `HedgingPhrases` | Compulsive hedging: "It's important to note that," "That being said," "Generally speaking," "As you might expect," etc. |
| `HollowAcknowledgment` | The staged-insight antithesis that names a thing and then declines to act on it: "names the gap without filling it," "identifies the problem without solving it," "raises the question without answering it," plus the shorthand "all analysis, no action." Gated on a notice-verb, a "without" gerund, and a back-referring pronoun, so an ordinary "left without saying goodbye" stays quiet. Distinct from `ContrastiveFormulas`, which negates a category rather than an action. |
| `HouseStyle` | The "house" compound for a project's own conventions: "the house style," "house tics," "the house formula," "the house voice," "house idioms." Agent prose picks up the figure whenever it writes about a repo's rules. The core style's one substitution rule, so each finding carries its mechanical drop-in correction ("project style," "project tics") and the fix tooling can apply it without judgment. The hyphenated compound stays quiet: "our in-house style guide" is in-house + style, not this figure. |
| `IncompleteComparison` | An intensified comparative missing its second term: "significantly lower risk," "substantially faster," "dramatically better results." A comparison has two terms, and AI prose habitually asserts the first and drops the second, leaving the reader to guess the baseline. A sentence that supplies it ("faster than the old parser," "lower compared with the previous release," "versus," "relative to") stays clean. Overlaps `OverusedVocabulary` on "significantly" and `FormalTransitions` on sentence-initial "Notably," so one span can raise two alerts; each rule still reads correctly on its own in a consumer's config. |
| `JourneyMetaphors` | The project narrated as travel: "along the way," "every step of the way," "most of the way there," "halfway there," a fix that "is on the way" or "well on its way," "en route to," a bug that "found its way into" production, "paves the way," "goes a long way," "a path forward," "on a path to," "on the road to," "bumps in the road," "down the road," "down the line," the determiner-gated "journey," the record that "made it through" or "makes it into" the index, and a reader who "walks the workflow." Bare "on the way" stays out for the manner sense ("depends on the way the shell splits arguments") and the entry-and-exit idiom ("closed on the way out"), "on the path to" for literal pointer and tree paths, and "the user journey" as a UX term of art; "paving the way" stays in `AICompoundPhrases` and "Embark on a journey" in `OpeningCliches`. Disable the rule for travel writing. The walked route now takes a counted or quantified stretch and the tier vocabulary ("walks three tiers," "walks each level of precedence," "walked up the ladder"), zero pre-LLM corpus hits. |
| `LabelAndExplain` | The "noun-phrase label: explanatory sentence" construction ("The dominant attendee report: developers build from scratch because finding an existing extension is harder than writing a new one."). A determiner-led label of up to four lowercase words, a colon, then a lowercase clause of 20 or more characters ending in sentence punctuation. The lowercase clause leaves the capitalized "Label: Sentence" case to `ColonUsage`; the length requirement skips short values ("The output: green.") and dotted file lists; a lookbehind skips copula clause-labels ("The following options are available: ..."). Also holds the curated dramatic-colon labels ("The catch:," "The takeaway:," "The upshot:") moved from `RhetoricalDevices`, which fire whatever follows the colon. A capitalized label ("The Redis cache: it evicts...") needs part-of-speech tagging to catch and stays uncovered. |
| `ListIntroductions` | Announcements of upcoming lists or summaries: "Below you'll find," "Here's a breakdown of," "Here's everything you need to know," "The following sections will," etc. |
| `MarketingHeadings` | Promotional-register heading clichés: "The Ultimate Guide," "Everything You Need to Know," "Mastering X," "Unlocking X," "The Power of X," "The Future of X," "Revolutionizing X," etc. |
| `Metacommentary` | Throat-clearing and self-commentary that narrates the text rather than adding content |
| `MicDrop` | Short dramatic sentences for manufactured emphasis in technical prose: "It matters." "Full stop." "And it shows." Contrastive fragments: "Dense, not cramped." Preference fragments: "Clarity over cleverness." Imperative mic-drops: "Trust the process." Categorical declarations: "Density is a feature." |
| `MortalityMetaphors` | Life, death, and survival handed to a process or a row: a run that "dies part way through," a fetch that "dies," a process that "can die mid-write," a row that "survives unchanged," a key that "survives" the rewrite, a file that "survives the rebase untouched" (moved from `FigurativeIdioms`), a cache entry that "outlives" the request, a record kept "for its whole life." The plain sentence says the process exited, the fetch failed, the row was kept, or the value is still referenced. An open determiner-gated subject with the beings, plants, batteries, and bulbs that literally die in the exceptions; threads and processes are not excepted, so the runtime register ("if the parent dies," "until the thread dies," about twenty pre-LLM corpus hits) and the compiler's "outlives" (nineteen, all escape analysis) fire on the maintainer's call. "Dead values" and "dead code" stay out as compiler vocabulary, and "survives all restarts" stays with `UniversalObject`. Disable the rule for biology or process-lifecycle writing. |
| `MotionMetaphors` | Motion and force verbs applied to data or control flow: a pipeline that "feeds" a stage or "feeds into" a ranker, a row that "strands," rows that "swamp" an index, a table that "dwarfs" the rest, a stage that "crowds out" the rest, a planner that "leans on" an index, a step that "mints" an identifier, a default "baked in," a config that "drives" the build, a pass that "shapes" the output, a stage that "cracks open" a record, a pass that "sheds" columns or "sheds light." Each verb gates on the construction a documentation-corpus audit saw, at zero to two pre-LLM corpus hits apiece. Measured out and left to a reader's own exceptions: "comes from," "arrives," "routes," "flows," "brings," "passes through," "heads," "sinks," "seeds," "fuses," "backs," and the sponge register's "squeezes" and "absorbs." Disable the rule for fluid or mechanical writing, where a pump feeds a line. A documentation-corpus census added the seated passenger and the lagging runner ("the loader seats the record in the cache," "the mirror trails the newest release"), each measuring zero across the pre-LLM corpora. |
| `FusionMetaphors` | Merging described as matter joining: a change that "folds" a helper "into" the caller, rules that "collapse into" one, a token that "absorbs" a sibling, a fix that "fuses" two paths, a flag that "couples" the cache "to" the writer. The plain verbs are merged, combined, added, and joined, with both things named. Every token gates on the verb plus a determined object or destination, so "a fold," "the collapse," and "tight coupling" stay out; the family measures nine across the seven pre-LLM corpora ("folding it directly into the Hasher trait," "collapse to wall time," "absorbs the carry"), each the figure. Disable the rule for physics or chemistry writing. |
| `DepletionMetaphors` | Failure and slowdown described as a body or an engine giving out: a loop that "exhausts its budget," a retry that "starves" the writer "of" slots, a job that "stalls on" a lock, a query that "degrades on" large inputs. The plain sentence says what ran out, what waited, and on which limit. Each token gates on the complement that makes the verb figurative and measures zero across the seven pre-LLM corpora; the noun "starvation" and the scheduler's "stall" stay out. Disable the rule for writing about engines or nutrition. |
| `MicDropHeadings` | Tagline-style headings: "Clarity, not cleverness," "Simple, then fast," "Speed over correctness," "X first, Y second," etc. |
| `NarrativePivots` | Unearned dramatic pivots: "something shifted," "everything changed," "that changed everything," "changed the game," "rewrote the playbook," "flipped the script," "it was a wake-up call," etc. |
| `NegatedObject` | The spec-sheet negation, a verb with "no" moved onto its object: "allows no inline suppression," "makes no clock calls," "offers no guarantee," "requires no configuration," "poses no risk," "collects no telemetry," "leaves no trace," "knows no bounds." Idiomatic prose negates the verb instead ("doesn't allow inline suppression"). The "zero" spelling of the same move fires too ("requires zero configuration," "adds zero overhead"), while literal counts ("zero or more," Go's "zero value") stay quiet. The verb list is curated against pre-LLM corpora, so ordinary docs formulas with other verbs ("takes no arguments," "returns no value," "has no effect," "contains no cycles") stay quiet, as do degree idioms ("no more than," "fares no better," "starts no earlier than") and the pronoun "no one." The "nothing" spelling fires over the operations and possession verbs ("writes nothing of its own," "costs nothing," "deletes nothing," "holds nothing but derived data"), while "does nothing" stays quiet as the corpora's own name for a no-op. An intensifier may sit ahead of the "no" ("requires absolutely no configuration," "adds virtually no overhead," "introduces almost no risk"), the bare intensified absence fires on its own ("absolutely no data"), and the prepositional spelling fires behind the verbs that make a reassurance of it ("ships with no dependencies," "runs with zero configuration," "installs without any changes," "comes with no support") and behind the reassurance nouns whatever the verb ("with no configuration," "with no vendor lock-in"); "with no changes" stays out as the diff register. Human idioms built on the listed verbs ("makes no sense," "needs no introduction") still fire; add project exceptions where a file needs them. "Make no mistake" stays in `AbsoluteAssertions`, "do no harm" in `AnthropomorphicJustification`, "carries no" in `FigurativeCarries`, and the doubled absence ("with no X and no Y") in `NegatedPair`. The perception verbs join after a documentation-corpus census ("finds no match," "found no examples," "sees no difference"); both were measured out at first, and on the seven pre-LLM corpora the finding verb matches ten times (the Go survey posts writing "found no differences") and the seeing verb six times, each the construction itself, flagged on the maintainer's call. |
| `NegatedPair` | The coordinated negated pair, a fact stated by naming two absences: "with no database and no network," "needs neither the database nor a round-trip," "runs without a database or a round-trip," "doesn't need credentials and doesn't call the network." The plain form negates the verb once and says what the thing does. The prepositional spellings have no verb for `NegatedObject` to gate on, so this rule takes them; the determiner gates "without a X or a Y," because bare "without X or Y" is docs English eighty times over in the pre-LLM corpora, and "has neither" stays out with "has no." Also the "nor" continuation ("doesn't need credentials, nor does it call the network"), the sentence-initial pair with its own verb ("Neither the database nor the network is required"), and the asyndetic badge copy ("no setup, no config, no fuss"). The kept tokens match about thirty times across the corpora, each the construction itself, a third of them one repeated Go comment in the formal "nor does it" register. |
| `NegatedSubject` | The passive sibling of `NegatedObject`, the negated claim promoted to subject: "No configuration is required," "No data is collected," "No breaking changes are introduced," plus the elliptical badge copy "No signup required," "No credit card needed." Anchored to a sentence-initial capital "No," so the lowercase docs conditional ("if no timeout is specified, the default applies") stays quiet, as do the spec formulas "No error is returned," "No exception is raised," and "No whitespace is allowed," the degree and pronoun phrases ("no longer needed," "no one was harmed"), and the active past verb ("No law required them to file"). Also, from a documentation-corpus audit, the "gets" auxiliary ("No row ever gets deleted"), a curated adjective predicate ("No freeze is anonymous"), a curated intransitive verb ("No operational driver appears in the code"), the pronoun subjects "Nothing," "None of," and "Neither" ("Nothing upstream feeds the stage," "None of these writes a table," "Neither subcommand writes back"), and the relative-clause negated subject ("a row whose key no root reaches," "a file that no manifest names"), which is lowercase by nature and gates the word before "no" so `NegatedObject`'s tokens stay with it. Strengthened past that audit on the maintainer's ask: the modal, perfect, and progressive auxiliaries ("No data will be collected," "No changes have been made," "No lock needs to be held," "No warning should occur"), "Nothing" with the copula ("Nothing is collected," "Nothing else is required"), the "Zero" spelling with the curated predicates ("Zero configuration is required," "Zero setup required," while the digit in "Zero padding is allowed" stays quiet), the intensified subject ("Not a single line is wasted," "Not one test was touched"), and the mid-sentence declarative after "and," "but," or "because" ("and no data is lost"), while the consequence idiom "so no adjustment is needed" and Python's literal "None is returned" stay out. The human caveat register with kept predicates ("No other validation is performed," "No attempt is made," "Nothing changed") still fires; add project exceptions where a file needs them. |
| `NominalizedScopeChange` | The change-as-noun: "the widening covers the inflections," "after the narrowing, alerts stay identical," "the tightening of the gate," "this broadening adds three tokens." Naming an edit by its direction of travel instead of naming the rule and what it catches now. Gated on a determiner plus a scope-change gerund followed by punctuation, a preposition, or a common predicate verb, so the adjectival reading ("the widening gap," "a narrowing conversion") stays quiet. Prose about type narrowing or compiler conversions disables the rule. |
| `NounString` | Four consecutive common nouns: "the customer feedback analysis pipeline stalled," "the incident response playbook revision deadline slipped." A noun string compresses relationships that a phrase with prepositions or verbs would state outright, leaving the reader to reconstruct them. Like `CommitGitJargon`, a clarity rule rather than a statistical tell. A negated leading token anchors each stack to its start, so a longer stack raises one alert instead of one per four-noun window; the anchored part-of-speech tag keeps proper nouns out ("New York City Hall" stays clean); temporal nouns the tagger files as nouns ("yesterday," "today") never match. The threshold is four because three-noun compounds saturate technical prose ("config file path," "unit test suite"). Known edges: the tagger reads some verbs as plural nouns ("the unit test suite runs" registers a fourth noun), a stack that opens a paragraph has no anchor token and goes unseen, and established four-noun compounds ("database connection pool size") fire, so add project exceptions where those are entrenched. |
| `OpeningCliches` | AI-style openings: "In today's rapidly evolving landscape," "Without further ado," "Whether you're," etc. |
| `OrganicConsequence` | False inevitability: "emerges naturally," "a natural consequence," "follows naturally from," and the effortless-emergence figure where a result "falls straight out of" its premise. The manner adverb gates the emergence token, so a literal "the pen fell out of my pocket" stays quiet. |
| `OverusedVocabulary` | Words with documented AI overuse: "delve," "comprehensive," "unprecedented," "sophisticated," "salient," "efficacy," "paramount," "cognizant," "camaraderie," "palpable," "fleeting," "amidst," "genuinely," "genuine," "supercharge," "unleash," "democratize," etc. Verb forms (leverage, harness, etc.) moved to `OverusedVocabularyVerbs`. |
| `OverusedVocabularyVerbs` | Verb forms of AI vocabulary fingerprints: "leverage," "navigate," "showcase," "harness," "embark," "foster," "spearhead." Sequence-based for precision — noun forms such as "financial leverage" do not trigger. |
| `ParallelStaccato` | Back-to-back minimal sentences with parallel structure: "Engineers build. Managers ship." "Content carries the personality. Chrome doesn't." Solo two-word staccato: "Complexity scales." |
| `ParticipialPadding` | Present participle (-ing) phrases appended for shallow analysis: "highlighting its importance," "reflecting broader trends," "underscoring its role," "solidifying its position," etc. The #1 discriminating feature in the PNAS study (527% of human rate). |
| `PromotionalPuffery` | Ad-copy and travel-brochure language: "nestled in," "vibrant community," "a beacon of," "renowned for its," "has emerged as a," "left an indelible mark," etc. |
| `PseudoCleft` | The pseudo-cleft, a free relative as subject, a copula, then the short claim the sentence spent five words announcing: "What changed is the direction," "What you get is one row per blob," "What remains is the offset," "All you need is the offset," "The only thing that changes is the direction," "Where this pays off is the read path," "all it does is call the hook." The plain form puts the claim first ("The direction changes"). `ExplainerLeads` keeps the determiner-fronted spelling ("What the join does is," "What this buys is"), `RestatementMarkers` "What this means is," and `ColloquialAssessments` "all that matters," so this rule takes the pronoun and bare-verb subjects after "What," the "all" and "the only" frames, and "Where" with a verb of payoff. A question mark anywhere in the sentence keeps "What value is the default?" out, and the word after the copula has to be a determiner, quantifier, "that," "to," or a wh-word, which keeps "What remains is unclear" out. The six tokens match about twenty-eight times across the Go and Python standard libraries, each the construction in human hands. |
| `RedundantPrecaution` | Redundant-precaution idioms that signal over-engineering thinking: "belt and suspenders," "belt-and-suspenders," and the British "belt and braces." |
| `ResonateOveruse` | "Resonate" as an overused reception verb: "resonates with audiences," "resonates deeply." Flagged broadly; the only literal sense is physics and acoustics, so disable the rule for physics or audio writing. |
| `RestatementMarkers` | Redundant restatements: the formal openers ("In other words," "Simply put," "To be more specific," "Put another way," "which is to say"), the parallel restatement that points at a second case and says "same again" ("The same holds for writes," "The same is true of the index," "The same applies to the reader," "The same goes for every caller"), the framing opener that promises a practical or net reading and then repeats the claim ("In practice, the index is one file"; "In effect, the join reverses"; "In the end, one read"), and the sentence-initial "Meaning" gloss ("Meaning, the cache is cold," "Meaning the cache is cold"). The framing openers gate on the capital and the comma, since mid-sentence "in practice" and "in effect" are docs English a hundred times over in the Go and Python standard libraries; the kept tokens match about fifty times across the corpora, each the construction itself. "That is," stays out with a hundred and sixty sentence-initial hits as the Go doc-comment house gloss, and "Likewise," "Similarly," and "That is to say" stay in `FormalTransitions`. |
| `RhetoricalDevices` | Rhetorical question patterns: "Ask yourself:", "The test:", "When doing X, ask:" etc. |
| `RhetoricalSelfAnswer` | Self-posed rhetorical questions answered for dramatic effect: "The result/catch/worst part?" followed by an immediate answer. |
| `ScopePartition` | The scope partition, the setup that makes a reveal possible: the writer splits the world in two and fronts each half with a comma-fenced label. "On the read side, the lookup is one hop," "On the write side, every blob is hashed," "Read-side, the join is one hop," "Server-side, the token is checked," "At index time, the tokenizer runs once," "At query time, it runs again." The plain form makes the scope the subject ("A search reverses that join"). The comma is the gate: "on the right-hand side of" is geometry, "at link time, before we" is a trailing adverbial, and "at run time" without the fronting comma is technical English, so all of those stay quiet, as do the idioms "on the plus side" and "on the safe side." The kept tokens match eight times across the Go and Python standard libraries, six of them the crypto/tls docs pairing client and server. The paired "For X, ... For Y," opener across two sentences lives in `StackedAnaphora`. |
| `SelfReference` | Self-referential cross-references: "as mentioned above," "as noted earlier," "as we'll explore," etc. |
| `SemicolonUsage` | Semicolons used as an em-dash substitute: a comma-free, clause-final continuation ("It does one thing; it does it well."). Exempts the legitimate uses, which carry a comma (lists with internal punctuation, "; however," joins, complex clauses). `Google.Semicolons` still warns on the rest. |
| `SequencingMarkers` | Formulaic ordinal sequencing: "Firstly," "Secondly," "Thirdly," "The first takeaway," "The second benefit," etc. |
| `ServesAsDodge` | Inflated copula replacements: "serves as a," "stands as the," "represents a pivotal," "boasts a vibrant," etc. Use "is" or "are" instead. |
| `ShellNounCopula` | The shell noun and its copula, a throat-clear that promises content and then delivers it in a that-clause: "The problem is that the index goes stale," "The difference is that the second build read the cache," "One catch is that the daemon keeps the lock," "The question is whether a restart clears the cache," "The real issue here is that the socket closes early." The plain form drops the shell and starts the sentence at the claim. The noun list is curated to the shells; nouns that name a kind of statement ("the rule is that," "the invariant is that") stay out as docs content, `LabelAndExplain` keeps the colon spelling, and `Metacommentary` keeps the "here is" spellings of key, point, idea, and insight. The kept tokens match about eighty times across the Go and Python standard libraries, each the construction itself. |
| `ShipOveruse` | "Ship" as an AI overuse fingerprint: the release verb ("ship it," "ship fast," "ship the feature") and the maritime clichés ("run a tight ship," "the ship has sailed"). Deliberately broad with no exemptions, so the logistics verb and the vessel noun are flagged too. Disable the rule for maritime or logistics writing. |
| `StackedAnaphora` | Stacked repetition for emphasis: "No X. No Y. No Z." "It's X. It's Y. It's Z." etc. Also the paired scope opener across two consecutive sentences, "For search, that join reverses. For writes, the table takes one append," with the discourse markers ("For example," "For now,") excluded. |
| `StackedHedges` | A modal verb doubled with an epistemic adverb: "could potentially," "may possibly," "might conceivably." The modal already carries the uncertainty, and restating it is reflex, not caution; one hedge per claim, tied to a number where one exists, says more. Modal-first order only, so the idiomatic tail of "she did all she possibly could" stays quiet, and a single hedge ("this could break," "possibly affects") never fires. |
| `StrategyBuzzwords` | Strategy-deck buzzword metaphors: "growth flywheel," "competitive moat," "north star metric," "network effects," "first-mover advantage," "land grab." Each is scoped to the figurative sense, so the engine's flywheel, a castle's moat, and the real North Star stay clean. |
| `StrawmanContrast` | The strawman contrast tail, the "not X" half of the "not X, it's Y" formula moved to the end of the clause where it refutes an alternative nobody proposed: "walks the index, rather than walking the whole tree," "reads the offsets directly, instead of re-reading each file," "goes from chunk to blob, not the other way around," "is one read, rather than a scan," "keeps one copy, not one per caller," "reads the manifest, not the whole store." The plain form states what it does and stops. "Rather than" and "instead of" are ordinary English (about 1,750 hits across the pre-LLM corpora between them), so the gates are the comma and the construction after it held to the end of the sentence: a gerund or a determiner and its noun phrase. Sentence-initial "Rather than X, do Y," the human "but not the reverse," and "and vice versa" stay out; the kept tokens match about thirty times across the corpora, each the construction itself. |
| `StructureAnnouncements` | Narrating upcoming structure: "key takeaway," "quick recap," "to recap," "quick summary," "to put it plainly," "to put this in perspective," etc. |
| `SummativeAppositive` | The summative appositive, a finished clause reopened by a comma and an abstraction noun that grades the claim and then repeats it in a relative clause: "rebuilt on every read, a cost that shows up in the benchmarks," "sees one row, a distinction the old path never made," "drops the header, something no caller expects," "a detail worth noting," "which is exactly the point." The plain form puts the claim in a second sentence or stops at the comma. The label nouns are the evaluative abstractions agent prose reaches for (cost, fact, choice, guarantee, trade-off, and their kin), so an ordinary appositive naming a thing ("Alice, a friend of mine," "gofmt, a tool that rewrites files") stays quiet, as does a list ("a cost, a benefit, and a risk") and a regex definition ("a pattern that matches"). The bare "which is what" and "which is why" stay out as the human afterthought, forty hits between them in the pre-LLM corpora; the kept tokens match two, each the construction itself. |
| `SycophancyMarkers` | Flattering phrases: "Great question," "I'm happy to help," "You make an excellent point," etc. |
| `UniversalObject` | The mirror of `NegatedObject`, the universal quantifier on the object: "handles all edge cases," "covers every scenario," "addresses all concerns," "eliminates all ambiguity," "meets every requirement," "passes all checks," "guarantees all deliveries." The self-grading register where a change claims a clean sweep. The verb list is curated against the same pre-LLM corpora, so the operations family stays quiet ("returns all matches," "removes all elements," "finds all occurrences" are spec facts), along with the lock-comment register ("protects all fields"), doctest report output ("passed all tests"), the exception idiom ("eliminates all but the top level"), and the alternation reading of "every other." Base verb forms stay out, so modal and infinitive aspiration ("should handle all cases," "to cover all of them") never fires, except behind a plural subject directly ahead of the verb ("content rules cover every input"), where the base form is the present tense and a claim. Human coverage prose on the listed verbs ("Handles all POST requests") still fires; add project exceptions where a file needs them. |
| `UniversalSubject` | The passive sibling of `UniversalObject`, the universal quantifier promoted to subject: "All edge cases are handled," "Every concern has been addressed," "All inputs are validated," "Every effort has been made," plus the uncounted scoreboard "All tests pass," "All checks are green," and the quantified subject doing one thing to one object ("Every predicate reads a live root," "All rows carry a timestamp"), a curated-verb token that matches about twenty-five times across the pre-LLM corpora ("Every type satisfies the empty interface") in the same spec-truth register. Anchored to a sentence-initial capital, so the mid-sentence conditional ("when all bytes are consumed") stays quiet, as do adjective predicates ("All three parts are optional"), the resumptive floats that summarize a list just named ("X, Y, and Z are all copied," "have all been observed"), and the modal future ("All feedback will be addressed"). Unlike its siblings, the predicate slot is open (any participle) rather than corpus-curated: the docs uniformity sweep ("All tabs are expanded to spaces," "All whitespace is removed") flags on purpose, the same call as the figurative family, because the construction now floods AI prose. Add project exceptions where spec formulas are deliberate. The counted scoreboard ("All 47 tests passing") stays in `CommitTestEnumeration`. |
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
- **Headless-infinitive openers:** AI opens sections with a noun + infinitive-modifier fragment ("Threads to pull on in Claude Code before the design hardens.") that reads as a section title punctuated as a sentence. Catching the structure requires distinguishing it from legitimate noun-phrase headings, which regular expressions can't do reliably. Some of the vocabulary that recurs in these fragments (thread-pulling metaphors, solidification metaphors) is now covered by `AICompoundPhrases`.
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

Most of the toolchain and the tasks that run it arrive from [`repotools`](https://github.com/tbhb/repotools) as a vendored payload: [vendir.yml](vendir.yml) names the tag, [vendir.lock.yml](vendir.lock.yml) records the commit it resolved to, and `vendir sync` writes the tool pins to `.config/mise/conf.d/` and the shared tasks to `.repotools/tasks/`. [mise.toml](mise.toml) holds what is specific to this repository and overrides any shared pin by name. Each configuration locks its downloads by digest beside itself, in [mise.lock](mise.lock) and `.config/mise/mise.lock`, so a contributor and CI run the same binaries. `mise run repotools:check-toolchain` measures the installed tools against those lockfiles, and `mise run repotools:check-vendored` catches a vendored file edited in place or a sync nobody committed. Both fail rather than warn. Every gate runs without a container runtime.

Commit messages go through the shared [`repotools`](https://github.com/tbhb/repotools) gates at the `commit-msg` stage. One hook enforces the Conventional Commits format and the length bounds. Another enforces the trailer rules, including a DCO `Signed-off-by` on every message. The remaining pair spell-check the buffer and lint it with this package's own `ai-tells` and `ai-tells-commits` styles. [AGENTS.md](AGENTS.md) describes the drafting workflow and the prose-lint output contract.

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
