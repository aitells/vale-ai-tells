# vale-ai-tells

A [Vale](https://vale.sh) package for detecting linguistic patterns commonly associated with AI-generated prose. Based on 2024-2025 research into vocabulary fingerprints, structural patterns, and rhetorical tells.

This package is designed for **technical documentation**, where clarity and directness matter more than style. It's less useful for creative writing, marketing copy, or other contexts where some of these patterns may be intentional choices.

<!-- vale proselint.Annotations = NO -->
> [!NOTE]
> The author created this package to help clean up AI-assisted technical documentation, not to disguise AI-generated content as human-written.
<!-- vale proselint.Annotations = YES -->

## Installation

Add the package to your `.vale.ini`:

```ini
StylesPath = styles
MinAlertLevel = suggestion

Packages = https://github.com/tbhb/vale-ai-tells/releases/download/v0.4.0/ai-tells.zip

[*.md]
BasedOnStyles = ai-tells
```

Then run:

```bash
vale sync
```

## Rules included

This package contains 22 rule files covering different categories of AI tells. All rules default to `error` level.

<!-- vale off -->

| Rule | Description |
|------|-------------|
| `AICompoundPhrases` | Compound phrases: "rich tapestry," "intricate interplay," "paradigm shift," "double-edged sword," etc. |
| `AffirmativeFormulas` | Revelation patterns: "Here's the thing," "And that's the beauty of it," "Let that sink in," etc. |
| `ClosingPleasantries` | Sign-off language: "I hope this helps," "Feel free to ask," "Don't hesitate to reach out," etc. |
| `ConclusionMarkers` | Formulaic conclusions: "In conclusion," "Ultimately," "At the end of the day," etc. |
| `ContrastiveFormulas` | Rhetorical contrasts: "It's not just X; it's Y," "The real question isn't X; it's Y," etc. |
| `DefensiveHedges` | Preemptive concessions: "This may seem X, but..." "Admittedly, X, but..." "At first glance," etc. |
| `EmDashUsage` | Em-dashes, which AI uses excessively |
| `EmphaticCopula` | Italicized *is*, *are*, *the* for manufactured profundity |
| `FalseBalance` | Evasive "both sides" language: "both sides present valid points," "nuanced approach," etc. |
| `FillerPhrases` | Padding and performative sincerity: "a wide range of," "in order to," "honestly," etc. |
| `FormalRegister` | Overly formal vocabulary: "utilize," "facilitate," "commence," etc. |
| `FormalTransitions` | Formal transitions: "Moreover," "Furthermore," "What's more," "Case in point," etc. |
| `HedgingPhrases` | Compulsive hedging: "It's important to note that," "That being said," "Generally speaking," etc. |
| `Metacommentary` | Throat-clearing and self-commentary: "This matters," "Let me explain," "At its core," etc. |
| `OpeningCliches` | AI-style openings: "In today's rapidly evolving landscape," "Without further ado," "Whether you're," etc. |
| `OrganicConsequence` | False inevitability: "emerges naturally," "a natural consequence," "follows naturally from," etc. |
| `OverusedVocabulary` | Words with documented AI overuse: "delve," "leverage," "comprehensive," "unprecedented," "sophisticated," etc. |
| `RestatementMarkers` | Redundant restatements: "In other words," "Simply put," "To be more specific," etc. |
| `RhetoricalDevices` | Rhetorical question patterns: "Ask yourself:", "The test:", "When doing X, ask:" etc. |
| `SelfReference` | Self-referential cross-references: "as mentioned above," "as noted earlier," "as we'll explore," etc. |
| `StackedAnaphora` | Stacked repetition for emphasis: "No X. No Y. No Z." "It's X. It's Y. It's Z." etc. |
| `SycophancyMarkers` | Flattering phrases: "Great question," "I'm happy to help," "You make an excellent point," etc. |

<!-- vale on -->

## Using with AI agents

Each error message provides actionable guidance for AI agents (or humans) to fix issues immediately. Messages include:

- A short prefix for quick identification (`AI hedge:`, `AI filler:`, etc.)
- The matched text
- A concrete action (delete, rewrite, replace, use simpler word)

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

## Proactive prevention with AI agent instructions

If you're using an AI coding assistant, add instructions to your project's `CLAUDE.md`, `AGENTS.md`, or similar file to prevent Vale violations before they happen:

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

For comprehensive detection, combine this package with statistical analysis tools.

### Supplementing with AI agent instructions

Vale can't detect structural patterns like sentence uniformity or paragraph rhythm. If you're using an AI coding assistant, add instructions to your project's `CLAUDE.md`, `AGENTS.md`, or similar file to cover what Vale misses:

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

Based on research including:

- [Delving into ChatGPT usage in academic writing through excess vocabulary](https://arxiv.org/abs/2406.07016) (arXiv, 2024)
- [Distinguishing academic science writing from humans or ChatGPT with over 99% accuracy](https://pmc.ncbi.nlm.nih.gov/articles/PMC10328544/) (PMC, 2023)
- [Wikipedia: Signs of AI writing](https://en.wikipedia.org/wiki/Wikipedia:Signs_of_AI_writing)
- Practitioner guides from 2024 and 2025

## Acknowledgments

Yes, Claude wrote most of this repository. It promised me all of these rules actually work because it "knows its own tendencies."

## License

MIT
