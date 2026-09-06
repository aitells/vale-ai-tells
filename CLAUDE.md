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
├── .config/mise/conf.d/        # Vendored repotools tool pins (vendir owns this)
├── .repotools/tasks/           # Vendored repotools shared tasks (vendir owns this)
├── .pre-commit-config.yaml
├── .vale.ini                   # Repo dev config (enables all three styles)
├── mise.toml                   # Repo-specific pins and tasks; selects the shared ones
├── mise.lock                   # Resolved versions, URLs, and digests
├── vendir.yml                  # The repotools payload: source, tag, target directories
├── vendir.lock.yml             # The commit each directory resolved to
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
mise run bootstrap   # vendir sync, mise install, vale sync, prek install
```

A clone already contains the vendored payload, because it is committed. Delete it and every `mise` command that reads tasks fails while loading the configuration, because the stamps in `mise.toml` extend templates only the payload defines. That is the enforcement, not a bug. `mise install` and `vendir sync` keep working through it, which is what recovers the tree.

**Testing rules locally:**

```bash
vale --config=.vale.ini test-document.md
mise run test    # the fixture guard: tells fire, subjects smoke-test, no false positives
```

**Measuring a candidate token:**

```bash
mise run corpus-build                          # once per machine, into ~/.cache/vale-ai-tells/corpus
mise run corpus-grep 'rather than [a-z]+ing'   # count a PCRE pattern per corpus, with sample paragraphs
```

A token is counted against human technical prose written before the models before it is added to a rule, and the count goes in the rule comment with an example hit or two. The Go and Python standard library corpora are reference prose, and the PEPs, Go proposals, Go blog, Rust RFCs, and Pro Git are explanation and argument, so quote the argumentative ones for a clause-level construction. A count in the tens that is the construction itself stays and gets documented, while one in the hundreds is ordinary English and measures out. Confirm the settled count through Vale over the corpus files, since Vale uses a different regex engine than the grep task. The header of `tools/corpus-build.sh` lists the sources and pins.

**Running the gates:**

Gates from the vendored payload use a `repotools:` prefix. The rest belong to this repository.

```bash
mise run lint                        # every linter below, in one pass
mise run repotools:check-vendored    # the vendored payload matches what git holds
mise run repotools:check-pins        # every tbhb/repotools pin site names one release
mise run repotools:lint-yaml         # ryl
mise run repotools:lint-markdown     # rumdl
mise run repotools:lint-config       # biome on JSON
mise run repotools:lint-spelling     # cspell
mise run lint-prose                  # Vale on the docs
mise run lint-messages               # Vale on each rule's own message: field (dogfooding)
mise run repotools:lint-toml         # tombi
mise run repotools:lint-mise         # mise fmt --check
mise run lint-editorconfig
mise run repotools:lint-workflows    # actionlint
mise run check-all                   # lint, test, and the full-history gitleaks scan
```

**Pre-commit hooks:**

```bash
mise run repotools:prek          # run hooks on staged files
mise run repotools:prek-all      # run hooks on all files
```

**Building and releasing:**

```bash
mise run build-package # write the three release zips locally
mise run release vX.Y.Z
```

## Rule conventions

All rules use `error` level by default. Users can override this in their `.vale.ini`. Core rules use Vale's `existence` and `sequence` extensions, plus `occurrence` for the density rule and `substitution` for the house-compound swaps. The experimental style adds `script` (Tengo), `metric`, `capitalization`, and `substitution` rules. Each rule needs:

- `message`: Clear explanation of why the rule flags the pattern
- `level`: Always `error`
- `tokens` or `swap`: The patterns to match
- A comment recording what the tokens cost on the pre-LLM corpora and what was measured out, from the corpus tasks above

Messages must pass the `ai-tells` style themselves. Avoid em-dashes and anthropomorphic or cliché idioms. Name the good word rather than quoting the flagged one. Write each message as `AI <label>: '%s'. <concrete action>.` so agents can act on it. `mise run lint-messages` enforces this via the `RuleMessage` View (selects the `message` field with Dasel and lints it as prose). It runs as part of `mise run lint`.

## Tone

Appreciate the irony: an AI working on a tool that detects AI writing. Lean into it. Find the humor in flagging your own tendencies and catching yourself mid-cliché while helping humans spot the patterns you statistically tend to produce.

## Quality standards

Before committing changes:

1. Test against `test-document.md`
2. Ensure rules don't have excessive false positives
3. Update README.md if adding/removing rules
