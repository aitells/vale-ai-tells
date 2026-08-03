#!/usr/bin/env bash
# context — everything drafting a pull request description needs, and
# nothing else.
#
# The write-pr-description SKILL.md inlines this through the !`...`
# preprocessor, so a forked writer starts from a settled picture rather
# than spending its first several calls rediscovering one. That fork is
# the point: the branch diff lands in the writer's context instead of
# the caller's, and the caller never pays for it.
#
# Read-only throughout. The pr preflight owns the workflow
# preconditions and the stale-draft sweep; this gathers material.
#
# Usage: context.sh [base-branch]
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
IFS=$' \t\n'

# gitr runs git for output this script parses, with every formatting
# knob pinned. log.showSignature is the one that matters most: it
# prepends a verification line per commit to stdout, ahead of the
# format string, so a --oneline listing silently becomes two lines per
# commit and any head -n cap shows half a branch as though it were all
# of it.
#
# Plain `git` stays available on purpose. Config reads, fetch, and push
# need the operator's real configuration: the sign-off identity may come
# from an includeIf work profile, and the network calls need credential
# helpers and any url.insteadOf rewriting.
gitr() {
  command git --no-pager \
    -c log.showSignature=false \
    -c color.ui=false -c color.diff=false -c color.status=false \
    -c core.quotePath=false \
    -c diff.noprefix=false -c diff.mnemonicPrefix=false \
    -c diff.renames=true -c diff.context=3 \
    "$@"
}

readonly DRAFT=PR_AGENTDESC.md
readonly DIFF_LINE_CAP=${WRITE_PR_DIFF_LINES:-800}

section() { printf '\n== %s ==\n' "$1"; }
none() { printf '(none)\n'; }

root=$(git rev-parse --show-toplevel)
cd "$root"
branch=$(git rev-parse --abbrev-ref HEAD)

default_branch=main
if remote_head=$(git symbolic-ref --quiet refs/remotes/origin/HEAD 2>/dev/null); then
  default_branch=${remote_head##*/}
fi

# The draft names its own base once one exists, so a revision keeps
# comparing against whatever the description already committed to.
base=${1:-}
if [ -z "$base" ] && [ -s "$DRAFT" ]; then
  base=$(sed -n 's/^base:[[:space:]]*//p' "$DRAFT" | head -1)
fi
[ -n "$base" ] || base=$default_branch

base_ref="refs/remotes/origin/$base"
git rev-parse --verify --quiet "$base_ref" >/dev/null || base_ref="refs/heads/$base"

section "branch"
printf 'branch: %s\n' "$branch"
printf 'base:   %s (comparing against %s)\n' "$base" "$base_ref"
printf 'root:   %s\n' "$root"

section "what this is"
if [ -s "$DRAFT" ]; then
  printf 'A draft already exists. You are revising it, not starting over.\n'
  printf 'Keep what still holds and change what the branch has outgrown.\n'
else
  printf 'No draft exists. You are writing the first one.\n'
fi

section "commits that would land"
landing=$(git rev-list --count "$base_ref..HEAD" 2>/dev/null || echo 0)
printf 'count: %s\n\n' "$landing"
if [ "$landing" = "0" ]; then
  printf 'Nothing to describe. Report that and stop.\n'
else
  gitr log --reverse --pretty=format:'--- %h %s%n%b' "$base_ref..HEAD" | head -n 250
fi

section "commit types on the branch"
if [ "$landing" != "0" ]; then
  gitr log --format='%s' "$base_ref..HEAD" |
    sed -n 's/^\([a-z][a-z]*\)[(!:].*/\1/p' | sort | uniq -c | sort -rn
  printf '\nThe title takes one of these. A squash merge turns it into the\n'
  printf 'commit subject on the default branch.\n'
else
  none
fi

section "changed files"
if [ "$landing" != "0" ]; then
  gitr diff --no-ext-diff --name-status "$base_ref...HEAD"
  printf '\n'
  gitr diff --no-ext-diff --stat "$base_ref...HEAD"
else
  none
fi

section "diff"
if [ "$landing" != "0" ]; then
  patch=$(gitr diff --no-ext-diff "$base_ref...HEAD")
  if [ "$(printf '%s\n' "$patch" | wc -l)" -le "$DIFF_LINE_CAP" ]; then
    printf '%s\n' "$patch"
  else
    printf '(diff exceeds %s lines. Read it a path at a time with\n' "$DIFF_LINE_CAP"
    printf 'gitr diff --no-ext-diff %s...HEAD -- <path>.)\n' "$base_ref"
  fi
else
  none
fi

section "template"
template=.github/pull_request_template.md
if [ -f "$template" ]; then
  cat "$template"
else
  printf 'NO TEMPLATE at %s. Report that and stop.\n' "$template"
fi

section "labels available"
if command -v gh >/dev/null 2>&1 && gh auth status >/dev/null 2>&1; then
  gh label list --limit 100 2>/dev/null || none
else
  printf '(gh unavailable; keep whatever labels the draft already carries)\n'
fi

section "open issues"
if command -v gh >/dev/null 2>&1 && gh auth status >/dev/null 2>&1; then
  issues=$(gh issue list --state open --limit 15 --json number,title \
    --template '{{range .}}#{{.number}} {{.title}}
{{end}}' 2>/dev/null || true)
  if [ -n "$issues" ]; then printf '%s\n' "$issues"; else none; fi
else
  none
fi

section "published description"
if command -v gh >/dev/null 2>&1 && gh auth status >/dev/null 2>&1; then
  number=$(gh pr list --head "$branch" --state open --json number --jq '.[0].number' 2>/dev/null || true)
  if [ -n "$number" ]; then
    printf 'Pull request #%s is open. What it currently says:\n\n' "$number"
    gh pr view "$number" --json body --jq '.body' 2>/dev/null || none
  else
    printf 'No open pull request yet.\n'
  fi
else
  printf '(gh unavailable)\n'
fi

section "current draft"
if [ -s "$DRAFT" ]; then
  cat "$DRAFT"
else
  printf '(absent)\n'
fi
