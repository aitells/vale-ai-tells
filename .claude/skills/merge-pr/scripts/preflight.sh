#!/usr/bin/env bash
# preflight — gather every fact the merge-pr skill needs before it
# writes a squash message or merges anything.
#
# The merge-pr SKILL.md inlines this through the !`...` preprocessor. It
# answers the questions that decide whether a merge should happen at all
# (state, draft status, review decision, check rollup, mergeability) and
# the ones that shape the message (title, description, the commits being
# collapsed, the trailers they carry).
#
# This skill also runs against pull requests nobody here authored, a
# dependency bump being the usual case, so the report never assumes the
# branch is checked out locally.
#
# Nothing here mutates anything. Usage: preflight.sh [number]
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

readonly DRAFT=SQUASH_AGENTMSG
readonly COMMIT_CAP=${MERGE_PREFLIGHT_COMMITS:-30}

section() { printf '\n== %s ==\n' "$1"; }
none() { printf '(none)\n'; }

root=$(git rev-parse --show-toplevel)
cd "$root"

section "gh"
gh_state=ok
if ! command -v gh >/dev/null 2>&1; then
  gh_state="gh is not installed"
elif ! gh auth status >/dev/null 2>&1; then
  gh_state="gh is not authenticated — run gh auth login"
fi
printf '%s\n' "$gh_state"
if [ "$gh_state" != ok ]; then
  printf 'Stop here and tell the operator.\n'
  exit 0
fi

branch=$(git rev-parse --abbrev-ref HEAD)
number=${1:-}
if [ -z "$number" ]; then
  number=$(gh pr list --head "$branch" --state open --json number --jq '.[0].number' 2>/dev/null || true)
fi

section "target"
printf 'local branch: %s\n' "$branch"
if [ -z "$number" ]; then
  printf 'pull request: NONE for this branch, and none given.\n'
  printf 'Pass the number as the skill argument, or open one with the pr skill.\n'
  printf '\nopen pull requests here:\n'
  gh pr list --state open --limit 20 \
    --json number,title,author,isDraft \
    --template '{{range .}}#{{.number}} {{.title}} ({{.author.login}}){{if .isDraft}} [draft]{{end}}
{{end}}' 2>/dev/null || none
  exit 0
fi
printf 'pull request: #%s\n' "$number"

section "state"
gh pr view "$number" --json number,title,state,isDraft,author,baseRefName,headRefName,mergeable,mergeStateStatus,reviewDecision,url \
  --template 'title:  {{.title}}
state:  {{.state}}{{if .isDraft}} (DRAFT — mark it ready before merging){{end}}
author: {{.author.login}}
{{.headRefName}} into {{.baseRefName}}
mergeable: {{.mergeable}} / {{.mergeStateStatus}}
review decision: {{if .reviewDecision}}{{.reviewDecision}}{{else}}(none required){{end}}
url: {{.url}}
' 2>/dev/null || printf '(could not read #%s)\n' "$number"

section "checks"
rollup=$(gh pr view "$number" --json statusCheckRollup \
  --jq '.statusCheckRollup[]? | [(.conclusion // .state // "PENDING"), (.name // .context)] | @tsv' 2>/dev/null || true)
if [ -z "$rollup" ]; then
  printf 'no checks reported\n'
else
  printf '%s\n' "$rollup" | sort | awk -F'\t' '{ printf "%-14s %s\n", $1, $2 }'
  printf '\nsummary: '
  bad=$(printf '%s\n' "$rollup" | grep -c -E '^(FAILURE|TIMED_OUT|CANCELLED|ACTION_REQUIRED|ERROR)' || true)
  pending=$(printf '%s\n' "$rollup" | grep -c -E '^(PENDING|IN_PROGRESS|QUEUED|EXPECTED|WAITING)' || true)
  if [ "$bad" != "0" ]; then
    printf 'FAILING. Do not merge. Hand this to the watch-pr skill instead.\n'
  elif [ "$pending" != "0" ]; then
    printf 'still running. Wait through the watch-pr skill before merging.\n'
  else
    printf 'all green.\n'
  fi
fi

section "commits being collapsed"
count=$(gh pr view "$number" --json commits --jq '.commits | length' 2>/dev/null || echo 0)
printf 'count: %s\n\n' "$count"
gh pr view "$number" --json commits \
  --jq '.commits[] | "--- " + .oid[0:7] + "\n" + .messageHeadline + "\n" + .messageBody' 2>/dev/null |
  head -n "$((COMMIT_CAP * 8))" || none

section "description as published"
gh pr view "$number" --json body --jq '.body' 2>/dev/null || none

section "files"
gh pr view "$number" --json files \
  --jq '.files[] | "\(.additions)+ \(.deletions)- \(.path)"' 2>/dev/null || none

section "preconditions"
if git check-ignore --quiet "$DRAFT" 2>/dev/null; then
  printf '%s gitignored: yes\n' "$DRAFT"
else
  printf '%s gitignored: NO — add it to .gitignore before drafting\n' "$DRAFT"
fi
if command -v mise >/dev/null 2>&1 && mise task info lint-squash-msg >/dev/null 2>&1; then
  printf 'mise run lint-squash-msg: present\n'
else
  printf 'mise run lint-squash-msg: ABSENT — stop and tell the operator\n'
fi
if [ -f .claude/skills/review-squash-message/SKILL.md ]; then
  printf 'review-squash-message skill deployed: yes\n'
else
  printf 'review-squash-message skill deployed: NO — run apm install\n'
fi

# A leftover squash draft belongs to whichever pull request last used
# this workflow, and merging one message into another pull request is
# the worst outcome available here. Say which it was drafted for.
stamp="$(git rev-parse --absolute-git-dir)/squash-agentmsg.reviewed"
if [ ! -s "$DRAFT" ]; then
  printf '%s: absent (expected before drafting)\n' "$DRAFT"
else
  drafted_for=$(head -1 "$DRAFT" | sed -n 's/.*(#\([0-9][0-9]*\))[[:space:]]*$/\1/p')
  if [ "$drafted_for" = "$number" ]; then
    printf '%s: present, drafted for #%s\n' "$DRAFT" "$number"
  else
    rm -f "$DRAFT" "$stamp"
    printf '%s: REMOVED. It was drafted for #%s, not #%s.\n' \
      "$DRAFT" "${drafted_for:-an unknown pull request}" "$number"
  fi
fi
