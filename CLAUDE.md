# Claude Code instructions

Refer to @AGENTS.md for commit conventions and the prose-lint output contract. What follows is specific to this repository.

## Project overview

vale-ai-tells provides a Vale package for detecting linguistic patterns commonly associated with AI-generated prose. It provides YAML rule files that flag vocabulary fingerprints, structural patterns, and rhetorical tells. The README tracks the current rule count.

## Repository structure

```text
vale-ai-tells/
├── styles/
│   ├── ai-tells/               # Core prose rules (*.yml)
│   ├── ai-tells-commits/       # Commit-message rules (*.yml)
│   ├── ai-tells-experimental/  # Opt-in structural and metric rules (*.yml)
│   └── config/                 # Tengo scripts, the agent template, the message view, vocabularies
├── .github/workflows/          # CI, security, release, and Renovate automation
├── .pre-commit-config.yaml
├── .vale.ini                   # Repo dev config (enables all three styles)
├── Justfile                    # Every gate and release recipe
├── mise.toml                   # Toolchain pins and every task
├── mise.lock                   # Resolved versions, URLs, and digests
├── README.md
├── AGENTS.md                   # Commit and prose-output contract for agents
├── EXPERIMENTAL.md             # Experimental-rule reference
├── CHANGELOG.md
├── TODO.md
├── test-document.md            # Positive fixtures (patterns should fire)
├── test-false-positives.md     # Negative fixtures (should stay clean)
└── test-commit-messages.md     # Commit-message fixtures
```

## Development workflow

**First-time setup:**

```bash
mise run setup   # mise install, vale sync, prek install
```

**Testing rules locally:**

```bash
vale --config=.vale.ini test-document.md
mise run test    # the fixture guard: tells fire, subjects smoke-test, no false positives
```

**Running the gates:**

```bash
mise run lint            # every linter below, in one pass
mise run lint-yaml       # yamllint
mise run lint-markdown   # rumdl
mise run lint-config     # biome on JSON
mise run lint-spelling   # cspell
mise run lint-prose      # Vale on the docs
mise run lint-messages   # Vale on each rule's own message: field (dogfooding)
mise run lint-toml       # tombi
mise run lint-just       # just --fmt --check
mise run lint-editorconfig
just lint-workflows  # actionlint
mise run check-all       # lint, test, and the full-history gitleaks scan
```

**Pre-commit hooks:**

```bash
mise run prek          # run hooks on staged files
mise run prek-all      # run hooks on all files
```

**Building and releasing:**

```bash
mise run build-package # write the three release zips locally
mise run release vX.Y.Z
```

## Rule conventions

All rules use `error` level by default. Users can override this in their `.vale.ini`. Core rules use Vale's `existence` and `sequence` extensions, plus `occurrence` for the density rule. The experimental style adds `script` (Tengo), `metric`, `capitalization`, and `substitution` rules. Each rule needs:

- `message`: Clear explanation of why the rule flags the pattern
- `level`: Always `error`
- `tokens` or `swap`: The patterns to match

Messages must pass the `ai-tells` style themselves: avoid em-dashes, anthropomorphic
or cliché idioms, and quoted examples of the flagged word (give the good word instead).
Write each message as `AI <label>: '%s'. <concrete action>.` so agents can act on it.
`mise run lint-messages` enforces this via the `RuleMessage` View (selects the `message`
field with Dasel and lints it as prose). It runs as part of `mise run lint`.

## Tone

Appreciate the irony: an AI working on a tool that detects AI writing. Lean into it. Find the humor in flagging your own tendencies and catching yourself mid-cliché while helping humans spot the patterns you statistically tend to produce.

## Quality standards

Before committing changes:

1. Test against `test-document.md`
2. Ensure rules don't have excessive false positives
3. Update README.md if adding/removing rules
