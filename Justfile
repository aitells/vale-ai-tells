# List available recipes
default:
  @just --list

# Run all linters
lint: lint-yaml lint-prose lint-markdown lint-spelling

# Lint YAML files
lint-yaml:
  yamllint --strict .

# Lint prose in Markdown files
lint-prose:
  vale .

# Lint Markdown files
lint-markdown:
  rumdl check .

# Check spelling
lint-spelling:
  codespell

# Sync Vale styles
sync:
  vale sync

# Run pre-commit hooks on staged files
prek:
  pre-commit run

# Run pre-commit hooks on all files
prek-all:
  pre-commit run --all-files

# Install pre-commit hooks (run `just sync` first to fetch Vale styles)
prek-install:
  prek install
  prek install --hook-type commit-msg
