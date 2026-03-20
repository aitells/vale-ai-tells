# Claude.md

## Project overview

vale-ai-tells is a Vale package for detecting linguistic patterns commonly associated with AI-generated prose. It provides 25 YAML rule files that flag vocabulary fingerprints, structural patterns, and rhetorical tells.

## Repository structure

```text
vale-ai-tells/
├── styles/ai-tells/          # Vale rule files (*.yml)
├── .github/workflows/        # Release automation
├── .pre-commit-config.yaml
├── .yamllint.yaml
├── .vale.ini                 # Sample configuration
├── Justfile
├── test-document.md          # Test file with AI patterns
└── test-false-positives.md   # Test file for false positive checks
```

## Development workflow

**First-time setup:**

```bash
just sync          # fetch external Vale styles (Google, write-good, proselint)
just prek-install  # install pre-commit hooks
```

**Testing rules locally:**

```bash
vale --config=.vale.ini test-document.md
```

**Running all linters:**

```bash
just lint           # run all linters (lint-yaml, lint-prose, lint-markdown, lint-spelling)
just lint-yaml      # yamllint on all YAML files
just lint-prose     # Vale on all files
just lint-markdown  # rumdl on all Markdown files
just lint-spelling  # codespell
```

**Pre-commit hooks:**

```bash
just prek          # run hooks on staged files
just prek-all      # run hooks on all files
```

**Creating a release:**

```bash
git tag vX.Y.Z
git push --tags
```

The GitHub Actions workflow automatically creates a release with `ai-tells.zip`.

## Rule conventions

All rules use `error` level by default. Users can override this in their `.vale.ini`. Rule files use Vale's `existence` or `sequence` extensions. Each rule needs:

- `message`: Clear explanation of why the rule flags the pattern
- `level`: Always `error`
- `tokens` or `swap`: The patterns to match

## Tone

Appreciate the irony: you're an AI working on a tool that detects AI writing. Lean into it. Find the humor in flagging your own tendencies and catching yourself mid-cliché while helping humans spot the patterns you're statistically prone to produce.

## Quality standards

Before committing changes:

1. Test against `test-document.md`
2. Ensure rules don't have excessive false positives
3. Update README.md if adding/removing rules
