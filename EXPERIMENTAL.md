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

## Calibration status

These thresholds are derived from research and validated against a small set of documents (synthetic AI text, curated test documents, AI-generated spec docs, human-varied prose). They need calibration against a larger corpus of real-world technical documentation.

Known limitations:

- **Sentence splitting is heuristic.** The scripts split on `[.!?]+\s+`, which mishandles abbreviations (Dr., U.S.), decimal numbers, and URLs. A full sentence tokenizer would improve accuracy.
- **Section splitting is markdown-only.** The heading-based section split assumes markdown. Other formats (reStructuredText, AsciiDoc) would need different splitting logic.
- **Per-section measurement can miss document-level uniformity.** If every section individually passes but the document as a whole is monotonous, these rules won't catch it.

## Future directions

Additional structural checks that could be built with Tengo scripts:

- **Content duplication:** Compare sentences or paragraphs within a document using word-overlap similarity (Jaccard index on word sets). Would catch near-verbatim repetition without requiring embeddings.
- **Tricolon density (document-level):** The existing `VerbTricolonDensity` rule works per-paragraph. A script could measure document-wide density of three-item lists of all types.
- **Sentence-start diversity index:** Instead of just flagging the most repeated opener, compute a diversity index (Shannon entropy) across all sentence starters. Lower entropy = more monotonous.

Patterns that would need capabilities beyond Tengo:

- **Elegant variation** (needs entity resolution / coreference)
- **One-point dilution** (needs semantic similarity / embeddings)
- **Unnecessary inline definitions** (needs syntactic parsing)

## Contributing

If you test these rules against real-world documents and find the thresholds need adjustment, open an issue with:

1. The document type (blog post, API docs, whitepaper, etc.)
2. Whether the rule fired or didn't when it should have
3. The approximate document length (word count)

This data will inform threshold calibration for promotion to the main `ai-tells` style.
