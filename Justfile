set unstable := true
set positional-arguments := true

# Default recipe
default: lint

# --- Setup ---

# Set up development environment
setup: prek-install vale-sync

# Install Homebrew dependencies from Brewfile
install-brew:
  brew bundle check || brew bundle install

# --- Format ---

# Format Markdown files
format-markdown *args:
  rumdl fmt {{ if args == "" { "." } else { args } }}

# --- Fix ---

# Fix Markdown files
fix-markdown *args:
  rumdl check --fix {{ if args == "" { "." } else { args } }}

# --- Lint ---

# Run all linters
lint: lint-yaml lint-prose lint-markdown lint-spelling

# Lint YAML files
lint-yaml *args:
  yamllint --strict {{ if args == "" { "." } else { args } }}

# Lint prose in Markdown files (excludes test-*.md)
lint-prose *args:
  vale --glob='!test-*.md' {{ if args == "" { "." } else { args } }}

# Lint Markdown files
lint-markdown *args:
  rumdl check {{ if args == "" { "." } else { args } }}

# Check spelling
lint-spelling *args:
  cspell {{ if args == "" { "." } else { args } }}

# --- Utilities ---

# Sync Vale styles
vale-sync:
  vale sync

# Run pre-commit hooks on changed files
prek:
  prek

# Run pre-commit hooks on all files
prek-all:
  prek run --all-files

# Install pre-commit hooks (run `just vale-sync` first to fetch Vale styles)
prek-install:
  prek install -t commit-msg -t pre-commit

# Assert test-false-positives.md produces zero Vale errors
test-clean:
  @echo "Checking for false positives..."
  @vale --config=.vale-test.ini test-false-positives.md && echo "Clean — no false positives."

# --- Rules ---

# Scaffold a new rule file
[script]
scaffold name:
  cat > "styles/ai-tells/{{ name }}.yml" << 'EOF'
  ---
  extends: existence
  message: "AI [type]: '%s'. [action]."
  level: error
  ignorecase: true
  tokens:
    -
  EOF
  echo "Created styles/ai-tells/{{ name }}.yml"

# Show token counts per rule
[script]
stats:
  echo "Token counts per rule (ai-tells):"
  total=0
  for f in styles/ai-tells/*.yml; do
    count=$(grep -c "^  - " "$f" 2>/dev/null || true)
    [[ -z "$count" ]] && count=0
    total=$((total + count))
    printf "  %-44s %3d\n" "$(basename "$f" .yml)" "$count"
  done
  echo ""
  echo "  Subtotal: $total"
  echo "  (Sequence rules report 1; actual verb count is higher)"
  echo ""
  echo "Token counts per rule (ai-tells-commits):"
  commits_total=0
  for f in styles/ai-tells-commits/*.yml; do
    count=$(grep -c "^  - " "$f" 2>/dev/null || true)
    [[ -z "$count" ]] && count=0
    commits_total=$((commits_total + count))
    printf "  %-44s %3d\n" "$(basename "$f" .yml)" "$count"
  done
  echo ""
  echo "  Subtotal: $commits_total"
  echo ""
  echo "  Grand total: $((total + commits_total))"

# --- Release ---

# Create an annotated release tag (e.g. just tag v1.5.0)
tag version:
  git tag -a {{ version }} -m "{{ version }}"

# Extract CHANGELOG entry for VERSION and update the GitHub release notes
[script]
update-release-notes version:
  set -euo pipefail
  ver="{{ version }}"
  ver_no_v="${ver#v}"
  repo=$(gh repo view --json nameWithOwner -q .nameWithOwner)
  prev_tag=$(git describe --tags --abbrev=0 "${ver}^" 2>/dev/null || true)
  notes=$(awk "/^## \[${ver_no_v}\]/{found=1; next} found && /^## \[/{exit} found && /^<!-- vale/{next} found{print}" CHANGELOG.md \
    | awk 'BEGIN{b=1} /^[[:space:]]*$/{if(!b)printf "\n"; b=1; next} {b=0; print}')
  if [[ -n "$prev_tag" ]]; then
    notes+=$'\n\n'"**Full Changelog**: https://github.com/${repo}/compare/${prev_tag}...${ver}"
  fi
  gh release edit "${ver}" --notes "${notes}"
  echo "Release notes updated for ${ver}"

# Tag, push, wait for the GitHub release workflow, then update release notes
[script]
release version:
  set -euo pipefail
  just tag {{ version }}
  echo "Pushing..."
  git push && git push --tags
  echo "Waiting for release workflow..."
  run_id=""
  for i in $(seq 1 30); do
    run_id=$(gh run list --workflow=release.yml --branch={{ version }} --limit=1 --json databaseId -q '.[0].databaseId' 2>/dev/null || true)
    [[ -n "$run_id" ]] && break
    sleep 2
  done
  if [[ -z "$run_id" ]]; then
    echo "Error: no release workflow run found for {{ version }} after 60s"
    exit 1
  fi
  gh run watch "$run_id" --exit-status
  just update-release-notes {{ version }}
  repo=$(gh repo view --json nameWithOwner -q .nameWithOwner)
  echo "Done! https://github.com/${repo}/releases/tag/{{ version }}"

# --- Changelog ---

# Generate full changelog
generate-changelog:
  cog changelog | { echo "# Changelog"; cat; } | rumdl check -d MD024 --fix --stdin > CHANGELOG.md

# Preview changelog since last release
preview-changelog:
  cog changelog --at $(git describe --tags)..HEAD -t full_hash | rumdl check -d MD041 --fix --stdin

# Generate release notes
[script]
generate-release-notes version="":
  v=$([[ -n "{{ version }}" ]] && echo "v{{ version }}" || echo "..$(git rev-parse HEAD)" )
  cog changelog --at $v -t full_hash | rumdl check -d MD024,MD041 --isolated --fix --stdin
