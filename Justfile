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

# Assert test-false-positives.md produces zero Vale errors
test-clean:
  @echo "Checking for false positives..."
  @vale --config=.vale.ini test-false-positives.md && echo "Clean — no false positives."

# Scaffold a new rule file
scaffold name:
  #!/usr/bin/env bash
  cat > "styles/ai-tells/{{name}}.yml" << 'EOF'
  ---
  extends: existence
  message: "AI [type]: '%s'. [action]."
  level: error
  ignorecase: true
  tokens:
    -
  EOF
  echo "Created styles/ai-tells/{{name}}.yml"

# Show token counts per rule
stats:
  #!/usr/bin/env bash
  echo "Token counts per rule:"
  total=0
  for f in styles/ai-tells/*.yml; do
    count=$(grep -c "^  - " "$f" 2>/dev/null || true)
    [[ -z "$count" ]] && count=0
    total=$((total + count))
    printf "  %-44s %3d\n" "$(basename "$f" .yml)" "$count"
  done
  echo ""
  echo "  Total: $total"
  echo "  (Sequence rules report 1; actual verb count is higher)"
