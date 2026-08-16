# Experimental rules: ai-tells-experimental

<!-- vale Google.Colons = NO -->
<!-- vale Google.Parens = NO -->
<!-- vale ai-tells-experimental.VocabularySwap = NO -->
The `ai-tells-experimental` style contains script-based rules that use Tengo to detect structural patterns beyond Vale's regular expression rules. These rules analyze document-level properties like sentence-length distribution and paragraph uniformity.

All experimental rules default to `warning` level. Releases publish them as a separate `ai-tells-experimental.zip` artifact (which includes the `config/scripts/` directory the Tengo rules need). Download it and unzip into your `StylesPath`, then opt in:

```ini
[*.md]
BasedOnStyles = ai-tells, ai-tells-experimental
```

## Why these exist

The `ai-tells` package catches lexical and phrasal patterns (vocabulary, transitions, rhetorical formulas). But some of the strongest AI writing signals come from structure, not vocabulary:

- AI produces sentences of strikingly consistent length (~27 words average with low variance), while human writing varies widely (3 to 40 words)
- AI paragraphs default to uniform blocks (3-5 sentences, 60-100 words each)
- AI reuses the same sentence openers throughout a document

Research sources identified these patterns, but they appeared under "Known patterns not covered" in the README because they require statistical analysis beyond token matching. Vale's `script` extension (Tengo) makes them possible within the Vale ecosystem.

## Rules

<!-- vale Google.Headings = NO -->

### SentenceLengthVariance

Measures the coefficient of variation (CV) of sentence word counts within each section (between markdown headings). Flags sections where CV falls below 0.30, indicating suspiciously uniform sentence lengths.

**Research basis:**

- Gibbs (2024): ChatGPT averages ~27 words per sentence with low variance; human writing ranges from 3 to 40 words
- PNAS (2025, Reinhart et al.): Instruction-tuned LLMs compress the sentence-length range humans naturally produce

**How it works:**

1. Splits the document into sections by markdown headings
2. Within each section, strips code blocks, list items, table rows, and HTML comments (these naturally show uniform lengths and lack prose)
3. Splits remaining prose into sentences by terminal punctuation
4. Filters out sentences shorter than 3 words
5. Requires at least 5 sentences and a mean length of 12+ words (skips sections of short test cases or examples)
6. Computes CV (standard deviation / mean) of sentence word counts
7. Flags sections where CV < 0.30

**Threshold rationale:** Human prose typically has CV > 0.40 (often much higher). AI-generated text clusters around CV 0.15-0.25. The 0.30 threshold sits between these ranges. Testing against real documents:

| Document type | Sentence CV | Fires? |
|---------------|-------------|--------|
| Synthetic uniform AI text | 0.065-0.080 | Yes |
| AI-generated test examples | 0.594 | No (varied example types) |
| AI-generated spec docs (edited) | 1.0-1.5 | No |
| Human-varied prose | 0.789 | No |

### ParagraphLengthVariance

Measures the CV of paragraph word counts within each section. Flags sections where CV falls below 0.25, indicating uniform paragraph blocks.

**Research basis:**

- Pangram Labs (2025): AI paragraphs tend toward roughly the same size (3-5 sentences, ~60-100 words each)
- Kassorla (2024): Describes "syntactic monotony" at the paragraph level as an AI structural tell

**How it works:**

1. Splits the document into sections by markdown headings
2. Within each section, splits by double newlines into paragraphs
3. Filters out code blocks, headings, list items, and short paragraphs (< 30 words, likely not multi-sentence prose)
4. Requires at least 4 qualifying paragraphs in a section
5. Computes CV of paragraph word counts
6. Flags sections where CV < 0.25

**Threshold rationale:** AI paragraphs cluster tightly around a mean. Human writers vary paragraph length for pacing, emphasis, and rhythm. Testing:

| Document type | Paragraph CV | Fires? |
|---------------|--------------|--------|
| Synthetic uniform AI paragraphs | 0.067 | Yes |
| AI competitive analysis (templated segments) | Varies by section | Yes (on templated sections) |
| AI-generated spec docs (edited) | 0.35-0.68 | No |

### SentenceStartRepetition

Counts the first word of each sentence within a section and flags when any single starting word appears in more than 30% of sentences (at least 3 occurrences, at least 6 sentences in section).

**Research basis:**

- PNAS (2025): AI text shows reduced variety in sentence-initial constructions
- Other sources note AI's tendency to start sentences with "The," "This," "It," or the subject noun, creating monotonous rhythm
- Complements the existing `StackedAnaphora` rule, which catches deliberate back-to-back repetition. This rule catches the subtler pattern where the same opener recurs throughout a section without appearing consecutively.

**How it works:**

1. Splits the document into sections by markdown headings
2. Within each section, strips code blocks and collapses whitespace
3. Splits into sentences by terminal punctuation
4. Extracts the first word of each sentence (lowercased, ignoring single-character words that naturally repeat like "I" and "a")
5. Flags when any word starts more than 30% of sentences (at least 3 times)

### ContentDuplication

Detects near-identical paragraphs within a document section using Jaccard word-overlap similarity. Flags the later occurrence when two paragraphs share more than 60% of their words.

**Research basis:**

- tropes.fyi: "Content Duplication" and "One-Point Dilution" identified as common AI composition patterns
- Wikipedia: Lists verbatim section repetition as a sign of unedited AI output

**How it works:**

1. Splits the document into sections by markdown headings
2. Collects prose paragraphs (filtering out code blocks, headings, list items, short lines under 8 words)
3. Normalizes each paragraph to a lowercase word set with punctuation stripped
4. Computes Jaccard index (intersection / union) for each paragraph pair
5. Flags the later paragraph when overlap exceeds 60%

**Tengo note:** Map iteration requires the two-variable form `for key, _ in map`. The single-variable `for key in map` compiles but never iterates.

### ContractionAvoidance

Detects documents that avoid contractions almost entirely despite using informal language. Uses a two-pass approach: first checks for informal markers (pronouns, questions), then computes the contraction ratio.

**Research basis:**

- PNAS (2025): GPT models use contractions at 60-63% of the human rate
- Pangram Labs (2025): "Minimal contractions" listed as an AI grammar tell
- Kassorla (2024): Absence of contractions identified as a formality signal

**How it works:**

1. Gate check: counts informal markers (first/second person pronouns, questions). Requires at least 2 to avoid flagging legitimately formal documents.
2. Requires at least 500 words (short docs don't have enough signal)
<!-- vale write-good.E-Prime = NO -->
3. Counts all expandable forms ("don't," "isn't," "won't," etc.) and their full-form equivalents
<!-- vale write-good.E-Prime = YES -->
4. Computes the ratio of contracted to total forms
5. Requires at least 8 total contractible forms for a useful sample size
6. Flags when the contraction ratio (contractions / total) falls below 0.10

### AverageSentenceLength

A metric-based rule (YAML only, without a script) that flags documents where the average sentence length exceeds 25 words.

**Research basis:**

- Gibbs (2024): ChatGPT averages ~27 words per sentence with low variance
- Human technical writing typically averages 15-20 words per sentence

**Formula:** `words / sentences > 25.0`

### LongWordDensity

A metric-based rule that flags documents where more than 40% of words contain 7+ characters.

**Research basis:**

- PNAS (2025): Mean word length ranks as a top-5 discriminating feature between AI and human text. Instruction-tuned LLMs shift toward longer, more formal vocabulary.

**Formula:** `long_words / words > 0.4`

### ComplexWordDensity

A metric-based rule that flags documents where more than 30% of words have 3+ syllables.

**Research basis:**

- PNAS (2025): Nominalizations (typically polysyllabic) appear at 150-214% of human rates in GPT output.

**Formula:** `complex_words / words > 0.3`

### HeadingTitleCase

A capitalization rule that flags markdown headings using Title Case instead of sentence case.

**Research basis:**

- Wikipedia "Signs of AI writing": "AI chatbots strongly tend to capitalize all main words in section headings."

**How it works:** Uses Vale's built-in `capitalization` extension. The relevant settings are `match: $sentence` and `scope: heading`. Acronyms like API and SQL, alongside proper nouns like GitHub, Docker, and PostgreSQL, live in a built-in exceptions list that the rule consults before flagging anything.

**Ordinal prefixes:** The rule's `prefix` setting strips a leading ordinal label before checking the case, with or without a colon. Headings such as `Section 1: Data collection methods`, `Appendix A`, `Chapter IV: The long road home`, and `1.1 Results` stay clean. The rule still checks the rest of the heading, so `Section 1: Data Tables Are Here` still trips it, and the first word after the prefix still needs a capital letter. Recognized labels: Appendix, Chapter, Example, Figure, Part, Phase, Section, Stage, Step, and Table, each followed by a number, a single letter, or a roman numeral. Bare numeric ordinals like `1.1` or `2.` also count.

**Adding project-specific exceptions:** Users can add their own exceptions (product names, domain terms) without modifying the rule. Drop the relevant entries into your project's `accept.txt` vocabulary file:

```text
# styles/config/vocabularies/MyProject/accept.txt
MyProductName
SomeDomainTerm
```

The rule merges these into its exceptions at runtime because it uses `vocab: true` (the default). Make sure your `.vale.ini` has `Vocab = MyProject` set.

**Changing the prefix or the built-in list:** Overrides in `.vale.ini` cover rule levels and on/off toggles, not fields like `prefix` or `exceptions`. On top of that, `vale sync` overwrites the packaged rule file on every run. To change those fields, copy the rule into a style your project owns and turn off the packaged copy. The [customization section in the README](README.md#copying-headingtitlecase-into-your-own-style) shows the steps.

### VocabularySwap

A substitution rule that provides concrete inline rewrite suggestions for common AI vocabulary fingerprints. Complements the existing `OverusedVocabulary` rule (which says "replace with a more specific or common word") by suggesting actual alternatives.

**How it works:** Uses Vale's `substitution` extension with a `swap` map of 56 entries covering 20 AI vocabulary words and their inflected forms. Only includes words where clear, universally applicable substitutions exist.

**Known limitation:** Can't distinguish noun vs verb usage. "Financial leverage" (legitimate noun) triggers with a suggestion to use "use" or "apply," which misses the mark in that context. The main `ai-tells` style handles this with POS-tag-aware sequence rules (`OverusedVocabularyVerbs`), but the substitution extension doesn't support POS tags.

**Turn it on in place of the core vocabulary rules, never alongside them:** the swap map overlaps `OverusedVocabulary` and `FormalRegister`, so running both double-flags one word.

### FigurativeAnchor

An existence rule that flags "anchor" used figuratively to ground or center an abstraction.

<!-- vale off -->

Example matches: "anchored in our values," "anchor the strategy," "an emotional anchor," "serves as an anchor."

**Why experimental:** anchor is heavily homographic, and no regular expression cleanly separates the figurative sense from the literal HTML anchor tag, a news anchor, an anchor tenant, or the anchoring bias. The rule stays at warning for that reason. Its exemptions cover the physical objects a thing literally anchors to, such as a wall or the seabed. The rest leans on the figurative shape. Turn the rule off in maritime, broadcast, or HTML writing.

<!-- vale on -->

<!-- vale ai-tells.FormalTransitions = NO -->
<!-- vale ai-tells.OverusedVocabulary = NO -->
<!-- vale ai-tells.ConclusionMarkers = NO -->
<!-- vale ai-tells.VerbTricolon = NO -->

### TransitionRepetition

Detects when the same formal transition phrase appears 3+ times within a document section. The existing `FormalTransitions` rule flags individual uses. This catches the density pattern where AI leans on the same connector repeatedly.

**How it works:**

1. Splits the document into sections by markdown headings
2. Strips code blocks and HTML comments
<!-- vale off -->
3. Counts occurrences of 20 common formal transitions (case-insensitive): "Moreover," "Furthermore," "Additionally," "Consequently," "Hence," "Thus," etc.
<!-- vale on -->
4. Flags when any single transition appears 3+ times in the same section

### SentenceStartEntropy

Measures Shannon entropy of sentence-starting words within document sections. A more nuanced version of SentenceStartRepetition that captures broad diversity rather than just the most repeated opener.

**Research basis:** A section could have no single dominant opener yet still sound monotonous (alternating between just "The" and "This"). Shannon entropy captures this broader pattern.

**How it works:**

1. Splits the document into sections, strips non-prose content
2. Extracts the first word of each sentence (lowercased, 2+ characters)
3. Requires at least 8 sentences in the section
4. Computes Shannon entropy: H = -sum(p * log2(p)) for each word's probability
5. Normalizes by H_max = log2(unique_count) to get a 0-1 scale
6. Flags sections where normalized entropy falls below 0.65

**Threshold rationale:** Normalized entropy of 1.0 means perfectly uniform distribution (every sentence starts with a different word). Below 0.65 means a small set of openers dominates the distribution. Testing showed 0.469 on sections where 9/10 sentences start with "The."

### TricolonDensityDocument

Detects when an unusually high proportion of enumerated lists in a document use exactly three items. AI defaults to three-item lists for everything, while human writers naturally vary between 2, 3, 4, and 5+ items.

**Research basis:**

- Gorrie (2024): Tricolon overuse identified as a key AI rhetorical tell
- tropes.fyi: "Tricolon Abuse" listed as a sentence-structure pattern
- Other sources note AI's "rule of three" default

**How it works:**

1. Scans the entire document (not per-section) for list patterns
2. Counts bullet/dash list groups by length (groups of exactly 3 vs other counts)
3. Counts inline comma-separated lists ("X, Y, and Z" patterns) with heuristic filtering to avoid false positives from subordinate clauses
4. Flags when all three conditions hold: at least 4 tricolons total, tricolons make up more than 60% of all enumerated lists, and at least 20% of prose sentences contain a tricolon

**The density gate:** The 20% sentence-density threshold prevents false positives on long documents with a small cluster of tricolons in one section. A truly AI-saturated document has tricolons spread throughout.

<!-- vale ai-tells.FormalTransitions = YES -->
<!-- vale ai-tells.OverusedVocabulary = YES -->
<!-- vale ai-tells.ConclusionMarkers = YES -->
<!-- vale ai-tells.VerbTricolon = YES -->

<!-- vale write-good.Passive = NO -->
<!-- vale ai-tells-experimental.PassiveVoice = NO -->
<!-- vale ai-tells-experimental.PassiveVoiceAdverb = NO -->

### PassiveVoice

Flags passive constructions where the participle directly follows the auxiliary ("was eaten," "is called," "has been made"). A sequence-based rule (part-of-speech tags, no script): the participle slot requires a VBN tag from Vale's tagger.

This rule and its two companions replace `Google.Passive`, `write-good.Passive`, and `write-good.E-Prime` for projects that ran those styles alongside `ai-tells`. The regex rules match a form of "to be" followed by any word ending in "ed" (or an irregular participle), with only whitespace allowed between them. That design fails in both directions:

- False positives on predicate adjectives and other "ed" words: "the results were mixed," "the talk was indeed useful," "the color is red."
- False negatives on every passive with an adverb in the gap: "was never used," "is automatically generated."

The VBN tag requirement clears the false positives, and `PassiveVoiceAdverb` covers the adverb gap. `write-good.E-Prime` doesn't need a replacement: it flags every form of "to be," including "it's" and "here's," which makes it a philosophy rather than a passive detector.

**Known limitations:** Participles that double as adjectives ("tired," "excited") tag as VBN even in predicate-adjective position, so "she was tired" fires. The rule deliberately defines no exception list. An allowlist would hide the passive sense of those same verbs ("the electron is excited by a photon"). The project's stance is that users decide what to except. The tagger also guesses VBN for some words outside its vocabulary, which produces an occasional flag on a non-participle.

### PassiveVoiceAdverb

The companion rule for the adverb-gap shape: it matches one adverb (RB) between the auxiliary and the participle ("was never used," "is automatically generated," "was not merged," "is rarely restarted"). The regex rules miss this entire shape. A separate rule because Vale sequences cannot mark a token slot optional, the same relationship `EmptyPaddingStacked` has to `EmptyPadding`. Two or more adverbs in the gap ("was not actually used") still slip through.

### PassiveDensity

Measures the share of sentences in each section that contain a passive construction. Occasional passive voice is ordinary English. Sustained passive voice across a section is the fingerprint of AI formal register, and no per-instance rule can see it. Complements the per-instance `PassiveVoice` rules the way `TricolonDensityDocument` complements `VerbTricolon`.

**How it works:**

1. Splits the document into sections by markdown headings
2. Within each section, strips code blocks, HTML comments, list items, and table rows
3. Splits remaining prose into sentences by terminal punctuation
4. Counts sentences containing an auxiliary, an optional adverb in the gap ("not," "never," or words like "automatically"), and a participle. This is a regex approximation of the tagged rules: it captures the participle and rejects "indeed," and requires regular "ed" forms to run four letters or longer (so "red" and "bed" stay clean). Individual misses and over-counts average out at section scale.
5. Requires at least 6 sentences in the section
6. Flags when at least 3 sentences and more than 35% of them contain a passive construction

**Threshold rationale:** Even formal human prose mixes voices, and academic writing (the most passive-heavy human register) stays well under the threshold in typical sections. AI formal register sustains agent-free passives at rates ordinary prose does not reach. The 35% value is an initial estimate from the same small validation set as the other rules and needs corpus calibration.

<!-- vale write-good.Passive = YES -->
<!-- vale ai-tells-experimental.PassiveVoice = YES -->
<!-- vale ai-tells-experimental.PassiveVoiceAdverb = YES -->

### NegationDensity

Counts the determiner "no" heading a noun phrase and flags paragraphs holding more than two. The construction is correct English and each instance reads fine, so the rule measures rate rather than judging any single use. It catches the writer who reaches for one negation and never varies it, in the way `TricolonDensityDocument` catches a structure no per-instance rule can see.

**How it works:**

1. Counts matches of the determiner "no" followed by a noun phrase within each paragraph
2. Excludes the adverbial "no longer" and "no matter" and the pronoun "no one," none of which is the determiner being measured
3. Counts a dotted object, so a repository with no .apm directory registers
4. Flags at three or more in one paragraph

**Threshold rationale:** Agent-authored prose sampled from 798 sessions runs 38.3 of these per 10k words. The Go standard library runs 13.5 and the Python standard library 11.1, close to a third of the agent rate. Per paragraph the separation is sharper. Across 4477 paragraphs of human-written markdown in the Go source tree, not one paragraph reached two. A max of 2 triggers only at three or more. That covers 0.073% of agent paragraphs and leaves the two-instance paragraph alone, since two independent negations in one paragraph are ordinary.

**Known limitation:** Prose whose purpose is prohibition exceeds the max for good reason. Specifications, license text, RFC language, and security controls stating what a system must not do should disable the rule.

## Calibration status

<!-- vale Google.Headings = YES -->

These thresholds come from research, validated against a small set of documents (synthetic AI text, curated test documents, AI-generated spec docs, human-varied prose). They need calibration against a larger corpus of real-world technical documentation.

Known limitations:

- **Sentence splitting relies on heuristics.** The scripts split on `[.!?]+\s+`, which mishandles abbreviations (Dr., U.S.), decimal numbers, and URLs. A full sentence tokenizer would improve accuracy.
- **Section splitting targets markdown only.** The heading-based section split assumes markdown. Other formats (reStructuredText, AsciiDoc) would need different splitting logic.
- **Per-section measurement can miss document-level uniformity.** If every section individually passes but the document as a whole reads monotonously, these rules won't catch it.

## Future work

<!-- vale ai-tells.EmDashUsage = NO -->
<!-- vale ai-tells.FormalRegister = NO -->
<!-- vale ai-tells.FormalTransitions = NO -->
<!-- vale ai-tells.OverusedVocabulary = NO -->
<!-- vale ai-tells.ConclusionMarkers = NO -->
<!-- vale Google.EmDash = NO -->

These patterns need capabilities Tengo can't provide. They'd require a separate tool or a Vale plugin with access to NLP libraries:

- **Elegant variation** — AI's repetition penalty causes unnatural synonym cycling ("the protagonist," "the key player," "the eponymous character" instead of reusing a name). Needs entity resolution and coreference tracking.
- **One-point dilution** — A single argument restated 10 ways across thousands of words. Needs semantic similarity (sentence embeddings) to detect that paragraphs say the same thing differently.
- **Unnecessary inline definitions** — AI inserts appositive definitions ("X, a [definition], does Y") even for audiences that know the term. Needs syntactic parsing to identify appositive structures.
- **Awkward analogies** — AI generates metaphors that seem superficially plausible but lack cultural specificity. Needs semantic analysis to judge metaphor quality.

<!-- vale ai-tells.EmDashUsage = YES -->
<!-- vale ai-tells.FormalRegister = YES -->
<!-- vale ai-tells.FormalTransitions = YES -->
<!-- vale ai-tells.OverusedVocabulary = YES -->
<!-- vale ai-tells.ConclusionMarkers = YES -->
<!-- vale Google.EmDash = YES -->

## Contributing

If you test these rules against real-world documents and find the thresholds need tuning, open an issue with:

1. The document type (blog post, API docs, whitepaper, etc.)
2. Whether the rule fired or didn't when it should have
3. The approximate document length (word count)

This data informs threshold calibration for promotion to the main `ai-tells` style.
