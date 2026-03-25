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

Packages = https://github.com/tbhb/vale-ai-tells/releases/download/v1.6.2/ai-tells.zip, \
  https://github.com/tbhb/vale-ai-tells/releases/download/v1.6.2/ai-tells-commits.zip

[*.md]
BasedOnStyles = ai-tells
```

Then run:

```bash
vale sync
```

## Linting commit messages

<!-- vale ai-tells.OverusedVocabulary = NO -->
<!-- vale ai-tells.AIAdjectiveNounPairs = NO -->
<!-- vale ai-tells-experimental.VocabularySwap = NO -->
AI-generated commit messages carry the same fingerprints as AI-generated prose, plus a few tells of their own: self-referential preambles like "This commit adds\u2026," trailing justification clauses like "\u2026ensuring consistency," buzzword adjective combos like "comprehensive tests" and "robust error handling," and gitmoji patterns.
<!-- vale ai-tells-experimental.VocabularySwap = YES -->
<!-- vale ai-tells.OverusedVocabulary = YES -->
<!-- vale ai-tells.AIAdjectiveNounPairs = YES -->

The `ai-tells-commits` style provides 6 rules purpose-built for commit messages, separate from the prose rules so you can opt in without pulling them into your docs.

### Commit message rules

<!-- vale off -->

| Rule | Description |
|------|-------------|
| `CommitSelfReference` | Self-narrating preambles: "This commit adds...," "This PR introduces...," "In this change...," "These changes ensure...," etc. |
| `CommitTrailingJustification` | Trailing clauses that restate the obvious: "...ensuring consistency," "...improving readability," "...which allows for," "for better maintainability," etc. |
| `CommitBuzzwords` | Vague adjective+noun combos: "comprehensive tests," "robust error handling," "proper validation," "various fixes," "relevant components," "necessary changes," etc. |
| `CommitHedging` | Inappropriate uncertainty for changes already made: "This should fix...," "This may help...," "seems to resolve...," etc. |
| `CommitEmoji` | Systematic gitmoji prefixes (✨🐛♻️📝⚡✅🔧🔥🚀 etc.) — emoji commit adoption has jumped from ~25% to ~75% of organizations, driven almost entirely by AI tools. |
| `CommitOverexplanation` | Filler that pads without informing: "As part of this change...," "The purpose of this commit...," "Summary of changes," "The following changes were made," etc. |

<!-- vale on -->

### Setup

Add a `[formats]` section and a named section for the commit message file to your `.vale.ini`:

```ini
[formats]
COMMIT_EDITMSG = md

[{COMMIT_EDITMSG,.git/COMMIT_EDITMSG}]
BasedOnStyles = ai-tells, ai-tells-commits
```

The glob covers both how pre-commit passes the path and direct Vale invocations. Use both styles together: `ai-tells` catches general vocabulary and structural tells, `ai-tells-commits` catches commit-specific patterns.

Add the commit-msg hook to your `.pre-commit-config.yaml`:

```yaml
  - repo: https://github.com/errata-ai/vale
    rev: 27593b0e0e7eb8f0c2b7fae0d93fa1cfaabceb2f # v3.13.0
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

This package contains 44 rule files covering different categories of AI tells. All rules default to `error` level.

<!-- vale off -->

| Rule | Description |
|------|-------------|
| `AbsoluteAssertions` | AI overconfidence: "the only way to," "the only real solution," "make no mistake," "there is no denying," "above all else," etc. Verify the claim or soften it. |
| `AIAdjectiveNounPairs` | AI adjective immediately preceding a noun: "holistic approach," "seamless integration," "transformative impact," etc. Currently at `warning` level. |
| `AICompoundPhrases` | Compound phrases: "rich tapestry," "intricate interplay," "paradigm shift," "double-edged sword," etc. |
| `AnthropomorphicJustification` | Treating abstractions like employees: "earns its keep," "does the heavy lifting," "pulls its weight," "pays for itself," "speaks for itself," etc. |
| `AffirmativeFormulas` | Revelation patterns: "Here's the thing," "And that's the beauty of it," "Let that sink in," etc. |
| `ClosingPleasantries` | Sign-off language: "I hope this helps," "Feel free to ask," "Don't hesitate to reach out," etc. |
| `ConclusionMarkers` | Formulaic conclusions: "In conclusion," "Ultimately," "At the end of the day," etc. |
| `ContrastiveFormulas` | Rhetorical contrasts: "It's not just X; it's Y," "These aren't X. They're Y," "This doesn't mean X. It means Y," "The real question isn't X; it's Y," "Not only X but also Y," etc. |
| `DefensiveHedges` | Preemptive concessions: "This may seem X, but..." "Admittedly, X, but..." "At first glance," etc. |
| `DespiteChallenges` | The "despite challenges" dismissal formula: "despite these challenges," "while challenges remain," "challenges notwithstanding," etc. |
| `EmDashUsage` | Em-dashes, which AI uses excessively |
| `EmphaticCopula` | Italicized copula verbs and determiners for manufactured profundity |
| `FalseBalance` | Evasive "both sides" language: "both sides present valid points," "nuanced approach," etc. |
| `FalseExclusivity` | False insider drama: "nobody talks about," "what most people miss," "the dirty secret," "the elephant in the room," etc. |
| `FillerPhrases` | Padding and performative sincerity: "a wide range of," "in order to," "honestly," etc. |
| `FormalRegister` | Overly formal vocabulary: "utilize," "facilitate," "commence," etc. |
| `FormalTransitions` | Formal transitions: "Moreover," "Furthermore," "What's more," "Case in point," etc. |
| `HedgingPhrases` | Compulsive hedging: "It's important to note that," "That being said," "Generally speaking," "As you might expect," etc. |
| `ListIntroductions` | Announcements of upcoming lists or summaries: "Below you'll find," "Here's a breakdown of," "Here's everything you need to know," "The following sections will," etc. |
| `Metacommentary` | Throat-clearing and self-commentary that narrates the text rather than adding content |
| `MicDrop` | Short dramatic sentences for manufactured emphasis in technical prose: "It matters." "Full stop." "And it shows." Contrastive fragments: "Dense, not cramped." Preference fragments: "Clarity over cleverness." Imperative mic-drops: "Trust the process." Categorical declarations: "Density is a feature." |
| `MicDropHeadings` | Tagline-style headings: "Clarity, not cleverness," "Simple, then fast," "Speed over correctness," "X first, Y second," etc. |
| `NarrativePivots` | Unearned dramatic pivots: "something shifted," "everything changed," "that changed everything," "it was a wake-up call," etc. |
| `OpeningCliches` | AI-style openings: "In today's rapidly evolving landscape," "Without further ado," "Whether you're," etc. |
| `OrganicConsequence` | False inevitability: "emerges naturally," "a natural consequence," "follows naturally from," etc. |
| `OverusedVocabulary` | Words with documented AI overuse: "delve," "comprehensive," "unprecedented," "sophisticated," "salient," "efficacy," "paramount," "cognizant," "camaraderie," "palpable," "fleeting," "amidst," etc. Verb forms (leverage, harness, etc.) moved to `OverusedVocabularyVerbs`. |
| `OverusedVocabularyVerbs` | Verb forms of AI vocabulary fingerprints: "leverage," "navigate," "showcase," "harness," "embark," "foster," "spearhead." Sequence-based for precision — noun forms such as "financial leverage" do not trigger. |
| `ParallelStaccato` | Back-to-back minimal sentences with parallel structure: "Engineers build. Managers ship." "Content carries the personality. Chrome doesn't." Solo two-word staccato: "Complexity scales." |
| `ParticipialPadding` | Present participle (-ing) phrases appended for shallow analysis: "highlighting its importance," "reflecting broader trends," "underscoring its role," "solidifying its position," etc. The #1 discriminating feature in the PNAS study (527% of human rate). |
| `PromotionalPuffery` | Ad-copy and travel-brochure language: "nestled in," "vibrant community," "a beacon of," "renowned for its," "has emerged as a," "left an indelible mark," etc. |
| `RestatementMarkers` | Redundant restatements: "In other words," "Simply put," "To be more specific," etc. |
| `RhetoricalDevices` | Rhetorical question patterns: "Ask yourself:", "The test:", "When doing X, ask:" etc. |
| `RhetoricalSelfAnswer` | Self-posed rhetorical questions answered for dramatic effect: "The result/catch/worst part?" followed by an immediate answer. |
| `SelfReference` | Self-referential cross-references: "as mentioned above," "as noted earlier," "as we'll explore," etc. |
| `SequencingMarkers` | Formulaic ordinal sequencing: "Firstly," "Secondly," "Thirdly," "The first takeaway," "The second benefit," etc. |
| `ServesAsDodge` | Inflated copula replacements: "serves as a," "stands as the," "represents a pivotal," "boasts a vibrant," etc. Use "is" or "are" instead. |
| `StackedAnaphora` | Stacked repetition for emphasis: "No X. No Y. No Z." "It's X. It's Y. It's Z." etc. |
| `StructureAnnouncements` | Narrating upcoming structure: "key takeaway," "quick recap," "to recap," "quick summary," "to put it plainly," "to put this in perspective," etc. |
| `SycophancyMarkers` | Flattering phrases: "Great question," "I'm happy to help," "You make an excellent point," etc. |
| `UnpackExplore` | Explainer announcements: AI's habit of announcing what it is about to explain rather than just explaining it. Phrases beginning with "Let me" or "Let us" followed by unpack, break down, dive in, walk through, examine, explore, etc. |
| `UrgencyInflation` | False urgency and importance assertions: "cannot be overstated," "more important than ever," "has never been more critical," "the stakes have never been higher," "at a critical juncture," "in an increasingly connected world," etc. |
| `VagueAttributions` | Claims attributed to unnamed authorities: "experts argue," "studies show that," "research suggests," "a growing body of evidence," etc. |
| `VerbTricolon` | Exactly-three parallel verb lists: "build, test, and deploy," "define, validate, and transform," etc. |
| `VerbTricolonDensity` | Multiple verb tricolons in one paragraph — LLM prose clusters exactly-three enumerations. |

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
<!-- vale Google.EmDash = NO -->
<!-- vale Google.Latin = NO -->

AI writing research documents these patterns, but they need analysis beyond Vale's token-matching capabilities:

- **Sentence-length uniformity:** AI produces sentences of near-uniform length, roughly 27 words, while human writing varies widely. Requires statistical analysis across the document.
- **Paragraph-length uniformity:** AI paragraphs tend toward uniform size, typically 3-5 sentences and 60-100 words each. Requires document-level measurement.
- **Dead metaphor repetition:** AI latches onto a single metaphor and repeats it 5-10 times throughout a piece. Requires tracking metaphor usage across the document.
- **One-point dilution:** A single argument restated 10 ways across thousands of words — circular repetition disguised as comprehensiveness. Requires semantic analysis.
- **Elegant variation:** AI's repetition-penalty pushes it to substitute synonyms unnaturally, cycling through "protagonist," "key player," "eponymous character" instead of reusing a name. Requires NLP-level analysis.
- **Content duplication:** Repeating entire sections or paragraphs verbatim within the same piece. Requires document-level diff analysis.
- **Unnecessary inline definitions:** AI habitually inserts appositive definitions like "X, a [definition], does Y" even when the audience already knows the term. Too many false positives for token matching.
- **Invented concept labels:** AI appends abstract problem-nouns like "paradox," "trap," "creep," and "divide" to domain words and treats them as established terms. Too many legitimate uses for token matching.

<!-- vale ai-tells.OverusedVocabulary = YES -->
<!-- vale ai-tells.EmDashUsage = YES -->
<!-- vale ai-tells.VerbTricolon = YES -->
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

Claude wrote the majority of rule definitions, documentation, and test cases in this repository. ChatGPT and Gemini generated text samples for cross-model validation. A human designed the rule categories, severity assignments, quality criteria, and the research-to-rule pipeline. A human validated every AI-generated rule against test documents containing known patterns.

The CITATION.cff lists the human author. AI tools are not listed as authors, consistent with [Committee for Publication Ethics (COPE) guidance](https://publicationethics.org/guidance/cope-position/authorship-and-ai-tools) on AI and authorship.

## Citation

If you use this package in research or want to cite it, see [`CITATION.cff`](CITATION.cff) for the citation metadata.

## License

MIT
