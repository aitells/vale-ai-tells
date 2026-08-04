#!/usr/bin/env bash
# context — every input a squash message review reads, gathered once.
#
# The review-squash-message SKILL.md inlines this through the !`...`
# preprocessor, so the reviewer starts holding the draft, the commits it
# collapses, the published description, and the diff. The fork is what
# makes that affordable: this text lands in the reviewer's context, and
# the caller never sees a line of it.
#
# Read-only throughout. The merge-pr preflight owns the preconditions
# and the stale-draft sweep; this gathers material. A reviewer has no
# standing to refuse a merge or delete a draft, and a missing input is a
# finding it reports rather than a state this corrects.
#
# Everything comes through gh rather than local refs, because this skill
# also runs against pull requests nobody here authored and often nothing
# local holds those commits at all.
#
# Usage: context.sh [repository-root]
#
# No -e. A report that dies partway leaves the reviewer holding some of
# its inputs with nothing saying which are missing, and a review run on
# half the commits is worse than one that never started.
set -uo pipefail

# --- environment hardening -------------------------------------------
# The agent reads this output, so the operator's preferences must not
# change its shape. LC_ALL pins collation. The unsets cover variables
# that silently retarget a command: GH_REPO sends gh at another
# repository, CDPATH makes a relative cd print somewhere else.
export LC_ALL=C
export GH_PAGER=cat
export GH_PROMPT_DISABLED=1
export PYTHONUTF8=1
unset CDPATH GH_REPO GH_HOST GREP_OPTIONS
IFS=$' \t\n'

readonly DRAFT=SQUASH_AGENTMSG
# The diff is the largest thing here and the only one worth bounding. A
# truncation says so and names the command that shows the rest, because
# a silent cap reads as a complete diff and a claim checked against half
# a branch is checked against nothing.
readonly DIFF_CAP=${REVIEW_SQUASH_DIFF_LINES:-1500}

section() { printf '\n== %s ==\n' "$1"; }
none() { printf '(none)\n'; }

root=${1:-}
if [ -z "$root" ]; then
  root=$(git rev-parse --show-toplevel 2>/dev/null)
fi
if [ -z "$root" ] || ! cd "$root" 2>/dev/null; then
  printf 'No repository at %s. Report this and stop.\n' "${1:-the working directory}"
  exit 0
fi
root=$(pwd -P)

section "repository"
printf 'root: %s\n' "$root"
printf 'Every path below is relative to it, and you are already there.\n'

section "the draft under review"
if [ ! -s "$DRAFT" ]; then
  printf '%s is absent or empty.\n' "$DRAFT"
  printf 'That is itself a finding. Report it and stop.\n'
  exit 0
fi
cat "$DRAFT"

# The subject carries the pull request number, and the merge script reads
# that reference back. A draft naming none is a finding, and so is one
# naming a pull request that does not exist.
number=$(head -1 "$DRAFT" | sed -n 's/.*(#\([0-9][0-9]*\))[[:space:]]*$/\1/p')

section "pull request"
if [ -z "$number" ]; then
  printf 'The subject names no pull request.\n'
  printf 'That is a form finding. Report it and stop.\n'
  exit 0
fi
printf 'number: #%s, from the subject line\n' "$number"

if ! command -v gh >/dev/null 2>&1; then
  printf 'gh is not installed, so nothing below could be gathered.\n'
  printf 'Report BLOCKED.\n'
  exit 0
fi
if ! gh auth status >/dev/null 2>&1; then
  printf 'gh is not authenticated, so nothing below could be gathered.\n'
  printf 'Report BLOCKED.\n'
  exit 0
fi

if ! view=$(gh pr view "$number" --json number,title,state,url,baseRefName,headRefName \
  --template 'title: {{.title}}
state: {{.state}}
{{.headRefName}} into {{.baseRefName}}
url:   {{.url}}
' 2>&1); then
  printf 'Could not read #%s:\n' "$number"
  printf '%s\n' "$view" | sed 's/^/  /'
  printf 'A subject naming a pull request that will not open is a finding.\n'
  exit 0
fi
printf '%s' "$view"

section "commits being collapsed"
# Bodies in full rather than subjects. A subject names what a commit did,
# the body carries why, and the reason is the first thing a squash loses.
commits=$(gh pr view "$number" --json commits \
  --jq '.commits[] | "--- " + .oid[0:7] + "\n" + .messageHeadline + "\n" + .messageBody' 2>/dev/null)
count=$(gh pr view "$number" --json commits --jq '.commits | length' 2>/dev/null)
printf 'count: %s\n\n' "${count:-unknown}"
if [ -n "$commits" ]; then
  printf '%s\n' "$commits"
else
  none
fi

section "description as published"
gh pr view "$number" --json body --jq '.body' 2>/dev/null || none

section "files"
gh pr view "$number" --json files \
  --jq '.files[] | "\(.additions)+ \(.deletions)- \(.path)"' 2>/dev/null || none

section "diff"
diff=$(gh pr diff "$number" 2>/dev/null)
if [ -z "$diff" ]; then
  none
else
  lines=$(printf '%s\n' "$diff" | wc -l)
  printf '%s\n' "$diff" | head -n "$DIFF_CAP"
  if [ "$lines" -gt "$DIFF_CAP" ]; then
    printf '\n[truncated: %s of %s lines shown. The rest is at\n' "$DIFF_CAP" "$lines"
    printf 'gh pr diff %s, and a claim about what is missing needs it.]\n' "$number"
  fi
fi
