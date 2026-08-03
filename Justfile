set unstable
set positional-arguments

# What is left in this file, and why.
#
# The mise config holds the toolchain and every gate that runs a pinned
# binary, whether this repo defines it or the vendored repotools payload
# does. Only one thing could not move there: the delegation recipes
# below. The APM primitives in .claude/ are pinned to tbhb/repotools and
# still spell their gates `just <recipe>`; three of them refuse to run
# when the recipe is absent. Each one forwards to the mise task of the
# same name, so the mise config stays the single definition.
#
# Everything else moved, gitleaks last of all. No recipe here runs a
# container any more, which is why the runtime probe and the docker-run
# prefix are gone with it. Run `mise task ls` for the full set.

# Run [script] recipes under bash; dash lacks [[ ]], <<<, and pipefail.

set script-interpreter := ['bash', '-eu']

# Default recipe: the full mise bar.
default:
    mise run lint
    mise run test

# --- APM compatibility ---

# Each recipe below exists because a skill under .claude/ names it. The
# definition lives in the mise config, this repo's or the vendored
# payload's; nothing here does work of its own.
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
    mise run repotools:lint-spelling {{ args }}

lint-markdown *args:
    mise run repotools:lint-markdown {{ args }}

lint-yaml *args:
    mise run repotools:lint-yaml {{ args }}

lint-toml:
    mise run repotools:lint-toml

lint-editorconfig:
    mise run lint-editorconfig

test:
    mise run test

# commit's preflight prints this by name when a git hook is missing, so the
# advice it gives has to resolve to something runnable.
prek-install:
    mise run repotools:prek-install
