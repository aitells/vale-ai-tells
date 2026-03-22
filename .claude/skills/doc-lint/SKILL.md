---
description: Lint and fix documentation issues, covering prose style with Vale and markdown formatting with rumdl
argument-hint: Optional file paths to lint (defaults to all markdown and MDX files)
disable-model-invocation: true
---

# Documentation linting

Lint and fix documentation issues in markdown and MDX files. This skill runs Vale for prose style and rumdl for markdown formatting, then applies fixes based on the output.

## Quick reference

| Tool         | Recipe               | What it checks                               |
| ------------ | -------------------- | -------------------------------------------- |
| Both         | `just lint-docs`     | Run spelling, prose, and markdown linting together |
| cspell       | `just lint-spelling` | Spelling errors, typos, and misspellings.    |
| vale         | `just lint-prose`    | Prose style, AI vocabulary, hedging, clarity |
| rumdl        | `just lint-markdown` | Markdown formatting, structure               |

<!-- vale ai-tells-experimental.HeadingTitleCase = NO -->
## Core workflow

### Step 1: Run linters

Run both linters on the target files.

**For specific files:**

```bash
just lint-docs path/to/file.md
```

**For all files:**

```bash
just lint-docs
```

You can also run linters individually with `just lint-spelling`, `just lint-prose`, or `just lint-markdown`.

### Step 2: Interpret output

Categorize issues by type:

1. **Auto-fixable markdown issues** - Fix directly: heading levels, list formatting, spacing
2. **Prose style issues** - Require judgment: rewrite sentences, simplify language
3. **Spelling issues** - Decide: add to accept.txt or cspell.json or rewrite
4. **Vocabulary issues** - Decide: add to accept.txt and/or cspell.json or rewrite
5. **False positives** - Technical terms that need vocabulary entries

### Step 3: Fix issues

<!-- vale Google.Colons = NO -->
**Markdown issues:** Edit files to fix formatting problems. Most amount to straightforward structural fixes.

**Prose issues:** Rewrite following AGENTS.md writing style:
<!-- vale Google.Colons = YES -->

<!-- vale off -->
- Use sentence case for headlines
- Avoid AI vocabulary (`delve`, `tapestry`, `robust`, `leverage`, `foster`)
- Cut hedging ("It's important to note…") and filler ("in order to")
- Prefer simple words: "use" not "utilize"
- Be direct, even blunt
<!-- vale on -->

<!-- vale Google.Colons = NO -->
**Vocabulary:** Before adding a term to the vocabulary, check whether the term represents a code identifier that should use backticks instead.
<!-- vale Google.Colons = YES --> Identifiers like function names, variable names, type names, and command-line flags belong in inline code formatting, not the vocabulary. Add to `.vale/config/vocabularies/ai-tells-site/accept.txt` only for legitimate prose terms such as project names and technical acronyms. One term per line. Supports regular expression patterns for case-insensitive matching.

### Step 4: Verify fixes

Re-run linters to confirm all issues resolved:

```bash
just lint-docs path/to/file.md
```

**The target: zero errors and zero warnings.** Both linters must pass clean.

## Handling difficult warnings

Don't dismiss warnings. Never call one "acceptable" or write it off as a false positive without asking the user first. If you hit a warning you genuinely can't resolve:

1. Explain the specific warning and why you think you can't fix it
2. Propose options: rewrite the sentence or add a vale directive; or update the vocabulary or ask the user to adjust the configuration
3. Let the user decide how to proceed

Most warnings have solutions:

- **Prose showing bad examples:** Wrap in `<!-- vale off -->` / `<!-- vale on -->`
- **Rule names with dots:** Use `<!-- vale Google.Spacing = NO -->` for specific rules
- **Technical terms:** Add to vocabulary or wrap in backticks
- **Style conflicts:** Rewrite the sentence, or try a different structure altogether

Don't assume warnings look inevitable. Fix them. Every rule in the linting configuration serves a purpose.

## Restrictions

**You can't edit `.vale.ini`.** The system blocks attempts to change the vale configuration file. If you need vale configuration changes such as path exclusions or alert levels, ask the user to make them.

You can freely edit the vocabulary file at `.vale/config/vocabularies/ai-tells-site/accept.txt`.

## Excluded paths

Vale skips these paths, as configured in `.vale.ini`:

- `.vale/**/*.md`
- `tmp/**/*.md`
