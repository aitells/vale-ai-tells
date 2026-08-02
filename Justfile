set unstable
set positional-arguments

# What is left in this file, and why.
#
# mise.toml holds the toolchain and every gate that runs a pinned binary.
# Two things could not move there:
#
#   1. The container-pinned gates below. They run from SHA-pinned images
#      rather than from a mise tool, and the shared Renovate preset tracks
#      their digests through a custom manager keyed on `^Justfile$`. Moving
#      the pins would silently drop them from Renovate's view.
#
#   2. The delegation recipes at the bottom. The APM primitives in .claude/
#      are pinned to tbhb/repotools and still spell their gates
#      `just <recipe>`; three of them refuse to run when the recipe is
#      absent. Each one forwards to the mise task of the same name, so
#      mise.toml stays the single definition.
#
# Everything else moved. Run `mise task ls` for the full set.

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

# renovate: datasource=docker depName=rhysd/actionlint

actionlint_version := "1.7.12"
actionlint_image := "docker.io/rhysd/actionlint:1.7.12@sha256:b1934ee5f1c509618f2508e6eb47ee0d3520686341fec936f3b79331f9315667"

# actionlint via its SHA-pinned Docker image (bundles shellcheck), tree mounted read-only.

actionlint := docker_run + ' -v "$(pwd):/repo:ro" -w /repo ' + actionlint_image

# renovate: datasource=docker depName=ghcr.io/gitleaks/gitleaks

gitleaks_version := "v8.28.0"
gitleaks_image := "ghcr.io/gitleaks/gitleaks:v8.28.0@sha256:cdbb7c955abce02001a9f6c9f602fb195b7fadc1e812065883f695d1eeaba854"
gitleaks_scan := docker_run + ' -v "$(pwd):/repo" -w /repo ' + gitleaks_image

# Default recipe: the full mise bar.
default:
    mise run lint
    mise run test

# --- Container-pinned gates ---

# Lint GitHub Actions workflows via actionlint (SHA-pinned Docker image).
lint-workflows:
    {{ actionlint }}

# Scan the working tree and full history for secrets via the pinned gitleaks image.
gitleaks:
    {{ gitleaks_scan }} git --verbose .

# Security sub-aggregator, so the security workflow invokes one recipe.
security: gitleaks

# --- APM compatibility ---

# Each recipe below exists because a skill under .claude/ names it. The
# definition lives in mise.toml; nothing here does work of its own.
#
# Preconditions the skills check and refuse to run without:

# commit — preflight verifies this recipe exists before drafting a message.
lint-commit-msg:
    mise run lint-commit-msg

# pr — same check before publishing a description.
lint-pr-description:
    mise run lint-pr-description

# merge-pr — same check before a squash merge.
lint-squash-msg:
    mise run lint-squash-msg

# rebase — verifies the replayed tree against `just check`, falling back to
# `just lint` where a repo has no `check`.
check:
    mise run check

# Recipes the skills invoke directly:

# write-prose-fix runs this before rewording anything by hand.
fix-prose-replacements file:
    mise run fix-prose-replacements {{ file }}

# fix-prose takes this as the general-purpose gate for a whole document.
lint-draft file:
    mise run lint-draft {{ file }}

# Recipes fix-pr prints as the local reproduction for a failing check. A
# name that resolves to nothing here sends the agent to a command that
# cannot run, so the diagnosis has to stay executable.
lint:
    mise run lint

lint-prose *args:
    mise run lint-prose {{ args }}

lint-spelling *args:
    mise run lint-spelling {{ args }}

lint-markdown *args:
    mise run lint-markdown {{ args }}

lint-yaml *args:
    mise run lint-yaml {{ args }}

lint-toml:
    mise run lint-toml

lint-editorconfig:
    mise run lint-editorconfig

test:
    mise run test

# commit's preflight prints this by name when a git hook is missing, so the
# advice it gives has to resolve to something runnable.
prek-install:
    mise run prek-install
