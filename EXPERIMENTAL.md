# Experimental rules: ai-tells-experimental

The `ai-tells-experimental` style contains script-based rules that use Tengo to detect structural patterns Vale's regex-based rules can't catch. These rules analyze document-level properties like sentence-length distribution and paragraph uniformity.

All experimental rules default to `warning` level. They ship in the same release zip as `ai-tells` but in a separate directory so users opt in independently:

```ini
[*.md]
BasedOnStyles = ai-tells, ai-tells-experimental
```

## Why these exist

The `ai-tells` package catches lexical and phrasal patterns (vocabulary, transitions, rhetorical formulas). But some of the strongest AI writing signals are structural, not lexical:

- AI produces sentences of strikingly consistent length (~27 words average with low variance), while human writing varies widely (3 to 40 words)
- AI paragraphs tend to be uniform blocks (3-5 sentences, 60-100 words each)
- AI reuses the same sentence openers throughout a document

These patterns were identified across multiple research sources but listed as "Known patterns not covered" in the README because they require statistical analysis beyond token matching. Vale's `script` extension (Tengo) makes them possible within the Vale ecosystem.

## Rules

### SentenceLengthVariance

Measures the coefficient of variation (CV) of sentence word counts within each section (between markdown headings). Flags sections where CV falls below 0.30, indicating suspiciously uniform sentence lengths.

**Research basis:**

- Gibbs (2024): ChatGPT averages ~27 words per sentence with low variance; human writing ranges from 3 to 40 words
- PNAS (2025, Reinhart et al.): Instruction-tuned LLMs compress the sentence-length range humans naturally produce

**How it works:**

1. Splits the document into sections by markdown headings
2. Within each section, strips code blocks, list items, table rows, and HTML comments (these are naturally uniform and not prose)
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

- Pangram Labs (2025): AI paragraphs tend to be roughly the same size (3-5 sentences, ~60-100 words each)
- Kassorla (2024): Describes "syntactic monotony" at the paragraph level as an AI structural tell

**How it works:**

1. Splits the document into sections by markdown headings
2. Within each section, splits by double newlines into paragraphs
3. Filters out code blocks, headings, list items, and short paragraphs (< 30 words, likely not multi-sentence prose)
4. Requires at least 5 qualifying paragraphs in a section
5. Computes CV of paragraph word counts
6. Flags sections where CV < 0.25

**Threshold rationale:** AI paragraphs cluster tightly around a mean. Human writers vary paragraph length for pacing, emphasis, and rhythm. Testing:

| Document type | Paragraph CV | Fires? |
|---------------|--------------|--------|
| Synthetic uniform AI paragraphs | 0.067 | Yes |
| AI competitive analysis (templated segments) | Varies by section | Yes (on templated sections) |
| AI-generated spec docs (edited) | 0.35-0.68 | No |

### SentenceStartRepetition

Counts the first word of each sentence within a section and flags when any single starting word appears in more than 30% of sentences (minimum 3 occurrences, minimum 6 sentences in section).

**Research basis:**

- PNAS (2025): AI text shows reduced variety in sentence-initial constructions
- Multiple sources note AI's tendency to start sentences with "The," "This," "It," or the subject noun, creating monotonous rhythm
- Complements the existing `StackedAnaphora` rule, which catches deliberate back-to-back repetition. This rule catches the subtler pattern where the same opener recurs throughout a section without being consecutive.

**How it works:**

1. Splits the document into sections by markdown headings
2. Within each section, strips code blocks and collapses whitespace
3. Splits into sentences by terminal punctuation
4. Extracts the first word of each sentence (lowercased, ignoring single-character words that naturally repeat like "I" and "a")
5. Flags when any word starts more than 30% of sentences (minimum 3 times)

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

**Tengo note:** Map iteration requires the two-variable form `for key, _ in map`. The single-variable `for key in map` silently produces no iterations.

### ContractionAvoidance

Detects documents that avoid contractions almost entirely despite using informal language. Uses a two-pass approach: first checks for informal markers (pronouns, questions), then computes the contraction ratio.

**Research basis:**
- PNAS (2025): GPT models use contractions at 60-63% of the human rate
- Pangram Labs (2025): "Minimal contractions" listed as an AI grammar tell
- Kassorla (2024): Absence of contractions identified as a formality signal

**How it works:**
1. Gate check: counts informal markers (first/second person pronouns, questions). Requires at least 2 to avoid flagging legitimately formal documents.
2. Requires at least 500 words (short docs don't have enough signal)
3. Counts all contractible full forms ("do not," "is not," "will not," etc.)
4. Counts all contractions ("don't," "isn't," "won't," etc.)
5. Requires at least 8 total contractible forms for a useful sample size
6. Flags when the contraction ratio (contractions / total) falls below 0.10

### AverageSentenceLength

A metric-based rule (YAML only, no script) that flags documents where the average sentence length exceeds 25 words.

**Research basis:**
- Gibbs (2024): ChatGPT averages ~27 words per sentence with low variance
- Human technical writing typically averages 15-20 words per sentence

**Formula:** `words / sentences > 25.0`

### LongWordDensity

A metric-based rule that flags documents where more than 40% of words are 7+ characters.

**Research basis:**
- PNAS (2025): Mean word length is a top-5 discriminating feature between AI and human text. Instruction-tuned LLMs shift toward longer, more formal vocabulary.

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

**How it works:** Uses Vale's built-in `capitalization` extension with `match: $sentence` and `scope: heading`. Includes an exceptions list for common acronyms (API, CLI, SQL, etc.) and proper nouns (GitHub, Docker, PostgreSQL, etc.).

**Adding project-specific exceptions:** Users can add their own exceptions (product names, domain terms) without modifying the rule. Add terms to your project's `accept.txt` vocabulary file:

```text
# styles/config/vocabularies/MyProject/accept.txt
MyProductName
SomeDomainTerm
```

These are merged into the rule's exceptions at runtime because the rule uses `vocab: true` (the default). Make sure your `.vale.ini` has `Vocab = MyProject` set.

### VocabularySwap

A substitution rule that provides concrete inline rewrite suggestions for common AI vocabulary fingerprints. Complements the existing `OverusedVocabulary` rule (which says "replace with a more specific or common word") by suggesting actual alternatives.

**How it works:** Uses Vale's `substitution` extension with a `swap` map of 56 entries covering 20 AI vocabulary words and their inflected forms. Only includes words where clear, universally applicable substitutions exist.

**Known limitation:** Cannot distinguish noun vs verb usage. "Financial leverage" (legitimate noun) triggers with a suggestion to use "use" or "apply," which is wrong in that context. The main `ai-tells` style handles this with POS-tag-aware sequence rules (`OverusedVocabularyVerbs`), but the substitution extension doesn't support POS tags.

<!-- vale ai-tells.FormalTransitions = NO -->
<!-- vale ai-tells.OverusedVocabulary = NO -->
<!-- vale ai-tells.ConclusionMarkers = NO -->
<!-- vale ai-tells.VerbTricolon = NO -->

### TransitionRepetition

Detects when the same formal transition phrase appears 3+ times within a document section. The existing `FormalTransitions` rule flags individual uses; this catches the density pattern where AI leans on the same connector repeatedly.

**How it works:**
1. Splits the document into sections by markdown headings
2. Strips code blocks and HTML comments
3. Counts occurrences of 20 common formal transitions (case-insensitive): "Moreover," "Furthermore," "Additionally," "Consequently," "Hence," "Thus," etc.
4. Flags when any single transition appears 3+ times in the same section

### SentenceStartEntropy

Measures Shannon entropy of sentence-starting words within document sections. A more nuanced version of SentenceStartRepetition that captures overall diversity rather than just the most repeated opener.

**Research basis:** A section could have no single dominant opener yet still be monotonous (alternating between just "The" and "This"). Shannon entropy captures this broader pattern.

**How it works:**
1. Splits the document into sections, strips non-prose content
2. Extracts the first word of each sentence (lowercased, 2+ characters)
3. Requires at least 8 sentences in the section
4. Computes Shannon entropy: H = -sum(p * log2(p)) for each word's probability
5. Normalizes by H_max = log2(unique_count) to get a 0-1 scale
6. Flags sections where normalized entropy falls below 0.65

**Threshold rationale:** Normalized entropy of 1.0 means perfectly uniform distribution (every sentence starts with a different word). Below 0.65 means the distribution is concentrated on a small set of openers. Testing showed 0.469 on sections where 9/10 sentences start with "The."

### TricolonDensityDocument

Detects when an unusually high proportion of enumerated lists in a document use exactly three items. AI defaults to three-item lists for everything; human writers naturally vary between 2, 3, 4, and 5+ items.

**Research basis:**
- Gorrie (2024): Tricolon overuse identified as a key AI rhetorical tell
- tropes.fyi: "Tricolon Abuse" listed as a sentence-structure pattern
- Multiple sources note AI's "rule of three" default

**How it works:**
1. Scans the entire document (not per-section) for list patterns
2. Counts bullet/dash list groups by length (groups of exactly 3 vs other counts)
3. Counts inline comma-separated lists ("X, Y, and Z" patterns) with heuristic filtering to avoid false positives from subordinate clauses
4. Flags when all three conditions hold: at least 4 tricolons total, tricolons make up more than 60% of all enumerated lists, and at least 20% of prose sentences contain a tricolon

**The density gate:** The 20% sentence-density requirement prevents false positives on long documents with a small cluster of tricolons in one section. A truly AI-saturated document has tricolons spread throughout.

<!-- vale ai-tells.FormalTransitions = YES -->
<!-- vale ai-tells.OverusedVocabulary = YES -->
<!-- vale ai-tells.ConclusionMarkers = YES -->
<!-- vale ai-tells.VerbTricolon = YES -->

## Calibration status

These thresholds are derived from research and validated against a small set of documents (synthetic AI text, curated test documents, AI-generated spec docs, human-varied prose). They need calibration against a larger corpus of real-world technical documentation.

Known limitations:

- **Sentence splitting is heuristic.** The scripts split on `[.!?]+\s+`, which mishandles abbreviations (Dr., U.S.), decimal numbers, and URLs. A full sentence tokenizer would improve accuracy.
- **Section splitting is markdown-only.** The heading-based section split assumes markdown. Other formats (reStructuredText, AsciiDoc) would need different splitting logic.
- **Per-section measurement can miss document-level uniformity.** If every section individually passes but the document as a whole is monotonous, these rules won't catch it.

## Roadmap

<!-- vale ai-tells.EmDashUsage = NO -->
<!-- vale ai-tells.FormalRegister = NO -->
<!-- vale ai-tells.FormalTransitions = NO -->
<!-- vale ai-tells.OverusedVocabulary = NO -->
<!-- vale ai-tells.ConclusionMarkers = NO -->
<!-- vale Google.EmDash = NO -->

### Metric-based rules (YAML only, no scripts)

Vale's `metric` extension provides built-in variables (`words`, `sentences`, `paragraphs`, `syllables`, `complex_words`, `long_words`) and arithmetic formulas evaluated at document level. These are trivial to implement.

**AverageSentenceLength** — Flag documents where `words / sentences` clusters near 27, the mean ChatGPT sentence length identified by Gibbs (2024). Human writing averages vary by genre but the tight clustering around a single value is the tell, not the value itself. This complements the per-section CV check by catching the document-level average.

**LongWordDensity** — Flag documents where `long_words / words` is unusually high. The PNAS study found instruction-tuned LLMs shift toward the "informational" pole of Biber's Dimension 1, characterized by longer words, more nominalizations, and more attributive adjectives. A high long-word ratio in text that isn't academic prose is a signal.

**ComplexWordDensity** — Similar to long word density but using `complex_words` (3+ syllables). AI defaults to polysyllabic vocabulary where simpler words would work ("utilize" instead of "use," "methodology" instead of "method"). High complex-word density in non-academic text suggests AI generation.

### Capitalization rules (built-in check type)

**HeadingTitleCase** — Flag markdown headings that use Title Case instead of sentence case. Wikipedia's "Signs of AI writing" guide specifically identifies Title Case headings as an AI tell: "AI chatbots strongly tend to capitalize all main words in section headings." Vale's `capitalization` extension with `match: $sentence` and `scope: heading` handles this directly.

### Substitution rules (better developer experience)

**OverusedVocabularySwap** — Convert some `existence` rules to `substitution` rules so Vale suggests specific replacements inline. Instead of "AI vocabulary: 'delve'. Replace with a more specific or common word," the output becomes "AI vocabulary: 'delve'. Use 'examine', 'look at', or 'cover' instead." The `swap` map provides `bad: good|good|good` pairs. Start with the highest-frequency words from OverusedVocabulary where clear substitutions exist.

### Repetition rules (built-in check type)

**TransitionRepetition** — Flag when the same formal transition ("Additionally," "Furthermore," "Moreover") appears multiple times within a section. The existing `FormalTransitions` rule catches each individual use; this would catch the density pattern where the same one recurs. Vale's `repetition` extension with `tokens` set to common transitions could work, though the built-in type only catches consecutive duplicates, which limits its usefulness. A Tengo script tracking transition frequency per section may be needed instead.

### Script-based rules (Tengo)

**ContentDuplication** — Compare sentences or paragraphs within a document using word-overlap similarity (Jaccard index on word sets). Would catch near-verbatim repetition without requiring embeddings. Tengo can split text into word sets and compute intersection/union ratios.

**TricolonDensityDocument** — The existing `VerbTricolonDensity` rule works per-paragraph. A script could measure document-wide density of three-item lists of all types, catching the pattern where every section has exactly three bullet points or three examples.

**SentenceStartEntropy** — Instead of just flagging the most repeated opener (as `SentenceStartRepetition` does), compute Shannon entropy across all sentence starters per section. Lower entropy = more monotonous. This is a more nuanced version of the current rule that would catch cases where no single word dominates but the overall diversity is still low.

### Consistency rules (built-in check type)

**ContractionConsistency** — Enforce that a document uses either contractions or full forms consistently. AI avoids contractions at 60-63% of human rate (PNAS, GPT models). A document that never uses contractions in otherwise informal prose is a signal. Vale's `consistency` extension with `either` pairs like `don't: do not` could flag the inconsistency, though the real tell is the complete absence of contractions rather than inconsistency.

### Beyond Vale (future tools)

These patterns need capabilities Tengo can't provide. They'd require a separate tool or a Vale plugin with access to NLP libraries:

- **Elegant variation** — AI's repetition penalty causes unnatural synonym cycling ("the protagonist," "the key player," "the eponymous character" instead of reusing a name). Needs entity resolution and coreference tracking.
- **One-point dilution** — A single argument restated 10 ways across thousands of words. Needs semantic similarity (sentence embeddings) to detect that paragraphs are saying the same thing differently.
- **Unnecessary inline definitions** — AI inserts appositive definitions ("X, a [definition], does Y") even for audiences that know the term. Needs syntactic parsing to identify appositive structures.
- **Awkward analogies** — AI generates metaphors that are superficially plausible but lack cultural specificity. Needs semantic analysis to evaluate metaphor quality.

<!-- vale ai-tells.EmDashUsage = YES -->
<!-- vale ai-tells.FormalRegister = YES -->
<!-- vale ai-tells.FormalTransitions = YES -->
<!-- vale ai-tells.OverusedVocabulary = YES -->
<!-- vale ai-tells.ConclusionMarkers = YES -->
<!-- vale Google.EmDash = YES -->

## Contributing

If you test these rules against real-world documents and find the thresholds need adjustment, open an issue with:

1. The document type (blog post, API docs, whitepaper, etc.)
2. Whether the rule fired or didn't when it should have
3. The approximate document length (word count)

This data will inform threshold calibration for promotion to the main `ai-tells` style.
