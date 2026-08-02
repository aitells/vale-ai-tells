#!/usr/bin/env bash
# scaffold-description — build PR_AGENTDESC.md from the repository's
# pull request template.
#
# The template is a body and nothing else, because that is all GitHub
# puts in the web form. The draft needs two things wrapped around it:
# YAML frontmatter carrying the pull request properties, and a level 1
# heading carrying the title. So this cannot be a copy.
#
# Doing it here rather than in an instruction means the sections always
# match the template as it stands today. An agent transcribing them by
# hand gets one wrong eventually, and the mismatch surfaces as a
# validator finding rather than as the transcription slip it was.
#
# The instructional comments carry through on purpose. They tell the
# writer what each section is asking for, and validate-description.sh
# refuses any that survive into a finished draft, so they cannot be
# mistaken for content.
#
# Never clobbers an existing draft. A description under revision is
# worth more than a fresh scaffold, and --force is the only way past.
#
# Usage: scaffold-description.sh [--force] [base-branch]
set -euo pipefail

# --- environment hardening -------------------------------------------
# The agent reads this output, so the operator's preferences must not
# change its shape. LC_ALL pins collation, because sort and the [a-z]
# ranges below mean different things under a UTF-8 locale. The unsets
# cover variables that silently retarget a command: GH_REPO sends gh at
# another repository, CDPATH makes a relative cd print somewhere else.
export LC_ALL=C
export GH_PAGER=cat
export GH_PROMPT_DISABLED=1
export PYTHONUTF8=1
unset CDPATH GH_REPO GH_HOST GREP_OPTIONS
IFS=$(printf ' \t\n')

readonly DRAFT=PR_AGENTDESC.md
readonly TEMPLATE=${PR_TEMPLATE:-.github/pull_request_template.md}
readonly TITLE_PLACEHOLDER='# <type>(<scope>)?: <description>'

force=0
if [ "${1:-}" = "--force" ]; then
  force=1
  shift
fi

root=$(git rev-parse --show-toplevel)
cd "$root"

if [ ! -f "$TEMPLATE" ]; then
  printf 'scaffold-description: no template at %s\n' "$TEMPLATE" >&2
  exit 1
fi

if [ -s "$DRAFT" ] && [ "$force" = 0 ]; then
  printf '%s already exists; left alone\n' "$DRAFT"
  exit 0
fi

base=${1:-}
if [ -z "$base" ]; then
  base=main
  if remote_head=$(git symbolic-ref --quiet refs/remotes/origin/HEAD 2>/dev/null); then
    base=${remote_head##*/}
  fi
fi

{
  printf -- '---\n'
  printf 'base: %s\n' "$base"
  printf 'draft: false\n'
  printf 'labels: []\n'
  printf 'reviewers: []\n'
  printf 'assignees: []\n'
  printf 'milestone:\n'
  printf -- '---\n\n'
  printf '%s\n\n' "$TITLE_PLACEHOLDER"
  cat "$TEMPLATE"
} >"$DRAFT"

printf 'scaffolded %s from %s\n' "$DRAFT" "$TEMPLATE"
printf 'Sections came from the template, so they match it exactly.\n'
printf 'The title and the labels are placeholders that fail the validator\n'
printf 'until something fills them.\n'
