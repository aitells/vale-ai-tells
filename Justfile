set unstable
set positional-arguments

# Run [script] recipes under bash; dash lacks [[ ]], <<<, and pipefail.

set script-interpreter := ['bash', '-eu']

# Locate a Docker-compatible runtime; override with CONTAINER_RUNTIME.

# The continuation lines of the `for` list below hang under the first
# candidate path rather than on a two-space grid, which is what shell
# style calls for and what `lint-editorconfig` would otherwise reject
# under this file's indent_size = 2. Exempt just that span rather than
# re-indent a block the sibling repos carry verbatim.
# editorconfig-checker-disable
container_runtime := env("CONTAINER_RUNTIME", `bash -c '
    docker_path=$(command -v docker 2>/dev/null || true)
    podman_path=$(command -v podman 2>/dev/null || true)
    for p in "$docker_path" \
             /usr/local/bin/docker \
             /opt/homebrew/bin/docker \
             /Applications/Docker.app/Contents/Resources/bin/docker \
             "$HOME/.docker/bin/docker" \
             "$HOME/.orbstack/bin/docker" \
             "$HOME/.rd/bin/docker" \
             "$podman_path" \
             /opt/podman/bin/podman; do
        if [ -n "$p" ] && [ -x "$p" ]; then echo "$p"; exit 0; fi
    done
    echo docker
'`)

# editorconfig-checker-enable

# Shared docker-run prefix. DOCKER_CONFIG points at a fresh empty dir so
# docker skips the osxkeychain helper; PATH prepends the runtime's dir
# for shells where docker isn't already on PATH.

docker_run := 'DOCKER_CONFIG="$(mktemp -d)" PATH="$(dirname ' + container_runtime + '):$PATH" ' + container_runtime + ' run --rm'

# The version CI pins through the setup-vale composite. Vale is
# brew-installed locally, so this is what `check-vale-version` compares
# against: a mismatch means local prose findings may not match the gate.

# renovate: datasource=github-releases depName=vale-cli/vale

vale_version := "3.17.0"

# The tombi release this repo's config and committed formatting are
# verified against. tombi is brew-installed, so `check-tombi-version`
# compares the local binary with it: a mismatch means local formatting
# may differ from what the gate expects.

# renovate: datasource=github-releases depName=tombi-toml/tombi

tombi_version := "1.2.5"

# renovate: datasource=docker depName=rhysd/actionlint

actionlint_version := "1.7.12"
actionlint_image := "docker.io/rhysd/actionlint:1.7.12@sha256:b1934ee5f1c509618f2508e6eb47ee0d3520686341fec936f3b79331f9315667"

# actionlint via its SHA-pinned Docker image (bundles shellcheck), tree mounted read-only.

actionlint := docker_run + ' -v "$(pwd):/repo:ro" -w /repo ' + actionlint_image

# renovate: datasource=docker depName=ghcr.io/gitleaks/gitleaks

gitleaks_version := "v8.28.0"
gitleaks_image := "ghcr.io/gitleaks/gitleaks:v8.28.0@sha256:cdbb7c955abce02001a9f6c9f602fb195b7fadc1e812065883f695d1eeaba854"
gitleaks_scan := docker_run + ' -v "$(pwd):/repo" -w /repo ' + gitleaks_image

# Default recipe: lint then test.
default: lint test

# --- Setup ---

# Set up the dev environment, refresh Vale styles, and install git hooks.
setup: install-brew install-tools prek-install

# Install Homebrew dependencies from Brewfile.
install-brew:
    brew bundle check || brew bundle install

# Refresh non-brew tooling (today: Vale's synced style packages).
install-tools:
    vale sync

# APM merges hook declarations into .claude/settings.json additively and
# never reconciles, while `apm audit --ci` replays the same merge from an
# empty tree and compares. A plain `apm install` therefore leaves two
# kinds of wreckage: a reordering the replay disagrees with forever, and
# entries for a hook upstream has since deleted, still firing. Clearing
# the keys APM owns first hands the merge the empty slate its replay
# assumes, so what lands is what the audit expects. Drop only the hooks
# key, so a hand-authored setting elsewhere in the file survives.
[script]
apm-sync: && lint-apm
    if [[ -f .claude/settings.json ]]; then
        jq 'del(.hooks)' .claude/settings.json > .claude/settings.json.tmp
        mv .claude/settings.json.tmp .claude/settings.json
    fi
    rm -f .claude/apm-hooks.json
    apm install

# Warn when the locally installed vale differs from the version CI pins.
# Advisory rather than fatal: local vale comes from Homebrew and drifts
# ahead on its own schedule, and that is fine so long as it stays
# visible. CI is the authority, so a mismatch means local findings may
# not match the gate.
[script]
check-vale-version:
    local=$(vale --version | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' | head -1)
    if [[ "${local}" != "{{ vale_version }}" ]]; then
        echo "warning: local vale ${local} != CI-pinned {{ vale_version }}" >&2
        echo "         run 'brew upgrade vale' or expect findings to differ" >&2
    else
        echo "vale ${local} matches the CI pin"
    fi

# --- Format ---

# Format Markdown in place (whitespace, list markers, code fences).
format-markdown *args:
    rumdl fmt {{ if args == "" { "." } else { args } }}

# Format JSON / JS / TS in place via biome.
format-config *args:
    biome format --write {{ if args == "" { "." } else { args } }}

# In-place TOML formatter (tombi 1.2.0) — the fixer paired with `lint-toml`'s --check
# gate. Rewrites whitespace/style only; key and array order are preserved (schema-driven
# reordering is disabled in tombi.toml). Excludes and lockfile skips come from tombi.toml.
format-toml:
    tombi format

# In-place Justfile formatter — the fixer paired with `lint-just`'s --check gate.
# `--fmt` is still an unstable just feature; this file's own `set unstable` already
# unlocks it, but pass --unstable explicitly so the recipe keeps working if that
# setting ever goes away. Takes no path args: --fmt only ever rewrites the justfile
# just resolved for this invocation.
format-just:
    just --fmt --unstable

# --- Fix ---

# Apply rumdl's auto-fixable Markdown rules.
fix-markdown *args:
    rumdl check --fix {{ if args == "" { "." } else { args } }}

# --- Lint ---

# Run every linter over the source tree.
lint: lint-yaml lint-markdown lint-config lint-spelling lint-prose lint-messages lint-toml lint-just lint-editorconfig

# Lint YAML via yamllint (--strict; config in .yamllint.yaml).
lint-yaml *args:
    yamllint --strict {{ if args == "" { "." } else { args } }}

# Lint Markdown structure against .rumdl.toml.
lint-markdown *args:
    rumdl check {{ if args == "" { "." } else { args } }}

# Lint JSON / JS / TS via biome.
lint-config *args:
    biome check --files-ignore-unknown=true {{ if args == "" { "." } else { args } }}

# Check spelling against the project dictionary (.cspell-words.txt).
lint-spelling *args:
    cspell --config .cspell.jsonc --no-summary --no-progress --no-must-find-files --exclude COMMIT_AGENTMSG --exclude PR_AGENTDESC.md --exclude SQUASH_AGENTMSG {{ if args == "" { "." } else { args } }}

# Lint prose in Markdown via vale. Findings render through the agent
# template committed in this repo's StylesPath, so a fix never needs a
# second context-gathering pass. The test fixtures trip rules on
# purpose, and the generated CHANGELOG.md carries cog's Title-Case
# section headings, so both stay out of the walk. The apm* entries cover
# the APM manifest, lockfile, and gitignored package cache, none of which
# carry prose to lint.
lint-prose *args:
    vale --output=ai-tells-agent.tmpl --glob='!{LICENSE,CHANGELOG.md,test-*.md,styles/*,pkg/*,tmp/*,.claude/worktrees/*,COMMIT_AGENTMSG,PR_AGENTDESC.md,SQUASH_AGENTMSG,apm.yml,apm.lock.yaml,apm_modules/*}' {{ if args == "" { "." } else { args } }}

# Lint each rule file's own `message:` field with the ai-tells prose style, so
# the package's diagnostics don't contain the patterns they flag. Uses the
# RuleMessage View (styles/config/views/RuleMessage.yml) to select the field.
lint-messages:
    vale --config=.vale-messages.ini --output=ai-tells-agent.tmpl styles/ai-tells styles/ai-tells-commits styles/ai-tells-experimental

# tombi is the TOML gate (tombi 1.2.0): it lint-checks every tracked *.toml.
# cog.toml, .rumdl.toml, and tombi.toml itself get syntax + style checks, validated
# offline against embedded SchemaStore schemas where one exists. We run the format gate
# in --check --diff mode here as well, so an unformatted TOML file fails `just lint`
# without being rewritten (`just format-toml` is the in-place fixer). --offline keeps the
# check hermetic against SchemaStore; --error-on-warnings promotes warnings to hard
# failures. Scope (include/exclude, lockfile skips, schema.strict=false) lives in
# tombi.toml, so this recipe passes NO path args — tombi walks the tree per that config.
# This deliberately departs from the sibling `*args`-default-`.` idiom because tombi
# centralizes scoping in tombi.toml rather than on the CLI, keeping excludes in one place.
lint-toml:
    tombi format --check --diff
    tombi lint --offline --error-on-warnings

# Warn when the locally installed tombi differs from the verified
# release. Advisory rather than fatal: tombi comes from Homebrew and
# moves on its own schedule, and that is fine so long as it stays
# visible rather than silently reformatting a file the gate then
# rejects.
[script]
check-tombi-version:
    local=$(tombi --version | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' | head -1)
    if [[ "${local}" != "{{ tombi_version }}" ]]; then
        echo "warning: local tombi ${local} != verified {{ tombi_version }}" >&2
        echo "         formatting may differ from what the gate expects" >&2
    else
        echo "tombi ${local} matches the verified release"
    fi

# Format-check this Justfile with just's own formatter, so the file that defines
# every other gate is itself gated. --check reports the difference and exits
# non-zero without touching the file; `just format-just` is the in-place fixer.
# just prints the whole justfile as diff context rather than a minimal hunk, so a
# failure here is long: run `just format-just` and read `git diff` instead.
lint-just:
    just --fmt --check --unstable

# Enforce .editorconfig (charset, line endings, final newline, trailing whitespace,
# indentation) with editorconfig-checker. Nothing else in the bar reads
# .editorconfig, so without this the file is documentation for editors only. The
# binary is spelled out in full: upstream's own Makefile also installs a short `ec`
# alias, but the Homebrew formula builds only `editorconfig-checker`, and the
# Brewfile is how this repo provisions the tool. With no path args the checker walks
# the files git tracks, which already keeps it off the gitignored Vale style
# packages; the remaining scope lives in .editorconfig-checker.json, whose Exclude
# list also covers CHANGELOG.md — `cog changelog` regenerates that file wholesale,
# and the prose recipes already skip it for the same reason. Indent width is not
# turned off tree-wide: the one block that needs an exemption (the container-runtime
# probe above) carries inline disable/enable markers.
lint-editorconfig:
    editorconfig-checker

# Lint GitHub Actions workflows via actionlint (SHA-pinned Docker image).
lint-workflows:
    {{ actionlint }}

# Check the deployed APM primitives against the lockfile. Drift here
# means .claude/ and apm.lock.yaml disagree; `just apm-sync` is the fix.
# --no-policy skips the org policy lookup, which resolves to nothing on a
# personal account.
lint-apm:
    apm audit --ci --no-policy

# Preview the commit-msg gates against the COMMIT_AGENTMSG draft.
# prek needs .pre-commit-config.yaml staged to run.
lint-commit-msg:
    prek run --stage commit-msg --commit-msg-filename COMMIT_AGENTMSG

# Check a drafted pull request description. The validator settles the
# mechanical questions (frontmatter, title shape, the template's
# sections, paths that exist); vale and cspell then read the prose the
# same way they read any other Markdown in the tree.
lint-pr-description:
    bash .claude/skills/pr/scripts/validate-description.sh
    vale --output=ai-tells-agent.tmpl PR_AGENTDESC.md
    cspell --config .cspell.jsonc --no-summary --no-progress PR_AGENTDESC.md

# The squash message merge-pr writes never passes through git's
# commit-msg hook, because GitHub authors that commit rather than this
# machine. Running the same four hooks over the draft here is what keeps
# a squash commit answerable to the rules every other commit meets.

# Pre-validate a drafted squash commit message against the commit-msg gates.
lint-squash-msg:
    prek run --stage commit-msg --commit-msg-filename SQUASH_AGENTMSG

# Every other prose recipe runs one checker over many files, so a
# document that clears `lint-prose` can still fail spelling and
# structure afterwards, which is how a short draft turns into four lint
# rounds. This runs vale, cspell, and rumdl over one document and
# reports all three at once.
#
# It also probes the path before trusting a clean run. Vale matches a
# path against the sections in .vale.ini exactly, and a path no section
# binds styles to loads no styles, reads the file, prints nothing, and
# exits 0 — byte for byte what a clean document produces. The recipe
# sends known-bad text through vale under the target's own path and
# reports an unscoped path rather than a pass.

# Lint one drafted document through every prose gate at once.
lint-draft file:
    bash tools/lint-draft.sh {{ file }}

# --- Test ---

# Run the fixture guard: tells fire, past-tense subjects smoke-test, no false positives
test: test-fires test-commit-past-tense test-clean

# Assert the tell corpus fires a healthy volume of errors under the test gate.
# .vale-test.ini binds ai-tells + ai-tells-experimental to test-document.md and
# ai-tells-commits to test-commit-messages.md at MinAlertLevel=error. The
# experimental rules ship at warning level, so only the error-level styles
# contribute here (ai-tells on the doc, ai-tells-commits on the commit corpus);
# the density metrics are validated separately. The floors catch a whole style
# silently ceasing to fire without pinning an exact count.
[script]
test-fires:
    set -uo pipefail
    doc=$(vale --config=.vale-test.ini --output=JSON test-document.md | grep -c '"Severity": "error"' || true)
    commit=$(vale --config=.vale-test.ini --output=JSON test-commit-messages.md | grep -c '"Severity": "error"' || true)
    echo "test-document.md: $doc errors (ai-tells)"
    echo "test-commit-messages.md: $commit errors (ai-tells-commits)"
    fail=0
    if [[ "$doc" -lt 400 ]]; then echo "FAIL: test-document.md fired $doc errors, expected at least 400"; fail=1; fi
    if [[ "$commit" -lt 40 ]]; then echo "FAIL: test-commit-messages.md fired $commit errors, expected at least 40"; fail=1; fi
    [[ "$fail" -eq 0 ]] && echo "Tell corpus fires as expected."
    exit "$fail"

# Smoke-test CommitPastTense on single-subject inputs. The rule's \A raw anchor
# only sees line 1, so the corpus fixture cannot exercise it. This feeds each
# documented subject through Vale on its own and checks the rule fires on
# past-tense or participle subjects and stays quiet on imperative ones.
[script]
test-commit-past-tense:
    set -uo pipefail
    dir=$(mktemp -d)
    cfg="$dir/smoke.ini"
    subj="$dir/subject.md"
    printf 'StylesPath = %s/styles\nMinAlertLevel = error\n[*]\nBasedOnStyles = ai-tells-commits\n' "$(pwd)" > "$cfg"
    fail=0
    check() {
      printf '%s\n' "$2" > "$subj"
      hits=$(vale --config="$cfg" --output=JSON "$subj" | grep -c 'CommitPastTense' || true)
      if [[ "$1" == fire && "$hits" -eq 0 ]]; then echo "FAIL (expected fire): $2"; fail=1
      elif [[ "$1" == clean && "$hits" -ne 0 ]]; then echo "FAIL (expected clean): $2"; fail=1
      else echo "ok ($1): $2"; fi
    }
    check fire 'Added rate limiting middleware'
    check fire 'Fixed off-by-one in iterator'
    check fire 'feat: Added rate limiting'
    check fire 'fix(auth): Fixed session expiry'
    check fire 'Refactoring the parser'
    check clean 'Add rate limiting middleware'
    check clean 'fix: Resolve race condition in scheduler'
    check clean 'feat(auth): Drop legacy session check'
    rm -rf "$dir"
    [[ "$fail" -eq 0 ]] && echo "CommitPastTense smoke test passed."
    exit "$fail"

# Assert test-false-positives.md produces zero Vale errors
test-clean:
    @echo "Checking for false positives..."
    @vale --config=.vale-test.ini test-false-positives.md && echo "Clean — no false positives."

# --- Package ---

# Build the three release zips. ai-tells and ai-tells-commits are
# style-only packages and zip flat, so their layout matches what every
# consumer's `vale sync` already expects. ai-tells-experimental needs the
# wrapper shape (a top-level dir holding a styles/ subtree) because its
# Tengo scripts live under styles/config, and that is also where the
# agent output template rides along. The project vocabulary and the
# dev-only message view stay out of the package. pkg/ and the zips are
# gitignored build output.
[script]
build-package:
    rm -rf pkg ai-tells.zip ai-tells-commits.zip ai-tells-experimental.zip
    (cd styles && zip -r ../ai-tells.zip ai-tells)
    (cd styles && zip -r ../ai-tells-commits.zip ai-tells-commits)
    mkdir -p pkg/ai-tells-experimental/styles
    cp -r styles/ai-tells-experimental pkg/ai-tells-experimental/styles/
    rsync -a --exclude='vocabularies/' --exclude='views/' styles/config/ pkg/ai-tells-experimental/styles/config/
    (cd pkg && zip -r ../ai-tells-experimental.zip ai-tells-experimental)
    echo "Built ai-tells.zip, ai-tells-commits.zip, ai-tells-experimental.zip"

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

# --- Security ---

# Scan the working tree and full history for secrets via the pinned gitleaks image.
gitleaks:
    {{ gitleaks_scan }} git --verbose .

# Security sub-aggregator, so the security workflow invokes one recipe.
security: gitleaks

# --- Aggregators ---

# Fast quality bar: lint then test.
check: lint test

# Deeper bar: check plus the full-history gitleaks scan.
check-all: check gitleaks

# --- Utilities ---

# Sync Vale styles and dictionaries.
vale-sync:
    vale sync

# Run pre-commit hooks on changed files.
prek:
    prek

# Run pre-commit hooks on every file in the tree.
prek-all:
    prek run --all-files

# Install the project's git hooks (commit-msg, pre-commit, pre-push, post-commit).
prek-install:
    prek install -t commit-msg -t pre-commit -t pre-push -t post-commit

# --- Changelog ---

# Generate CHANGELOG.md from Conventional Commit history. cog 7 carries
# the tag's `v` prefix into version headings; strip it from the heading
# text (the compare URL keeps the tag name) so the release-notes
# extraction in release.yml and the update-release-notes recipe, both
# matching `## [X.Y.Z]`, find the section.
generate-changelog:
    cog changelog | sed 's/^## \[v/## [/' | { echo "# Changelog"; cat; } | rumdl check -d MD024 --fix --stdin > CHANGELOG.md

# Preview changelog since last release
preview-changelog:
    cog changelog --at $(git describe --tags)..HEAD -t full_hash | rumdl check -d MD041 --fix --stdin

# Generate release notes
[script]
generate-release-notes version="":
    v=$([[ -n "{{ version }}" ]] && echo "v{{ version }}" || echo "..$(git rev-parse HEAD)")
    cog changelog --at $v -t full_hash | rumdl check -d MD024,MD041 --isolated --fix --stdin

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
    # `gh run watch --exit-status` reports success on a failed run, so poll
    # the run's own status and conclusion instead of trusting its exit code.
    status=""
    conclusion=""
    for i in $(seq 1 120); do
      read -r status conclusion <<< "$(gh run view "$run_id" --json status,conclusion -q '.status + " " + .conclusion')"
      [[ "$status" == "completed" ]] && break
      sleep 10
    done
    if [[ "$status" != "completed" ]]; then
      echo "Error: release run $run_id still $status after 20 minutes"
      exit 1
    fi
    if [[ "$conclusion" != "success" ]]; then
      echo "Error: release run $run_id concluded $conclusion"
      exit 1
    fi
    just update-release-notes {{ version }}
    repo=$(gh repo view --json nameWithOwner -q .nameWithOwner)
    echo "Done! https://github.com/${repo}/releases/tag/{{ version }}"
