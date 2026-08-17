#!/usr/bin/env bash
# squash-merge — the one thing in this workflow that merges a pull
# request, and the one that cleans up afterwards.
#
# GitHub will happily write the squash message itself, by concatenating
# every commit on the branch. That output has never passed a commit-msg
# hook, and it lands on the default branch where the whole toolchain
# assumes those hooks ran. So this workflow supplies the message, which
# means the message needs the same gates a commit gets: the linters, and
# a reviewer that did not write it.
#
# Cleanup lands here for the same reason create-pr owns its own: there
# is no post-merge hook to hang it on. The drafts that the pull request
# workflow left behind become garbage the moment the branch merges, and
# this is the code that watched that happen.
#
# Usage: squash-merge.sh [pull-request-number]
# Written to bash 3.2.
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

readonly SQUASH_DRAFT=SQUASH_AGENTMSG
readonly DESC_DRAFT=PR_AGENTDESC.md

root=$(git rev-parse --show-toplevel)
cd "$root"
git_dir=$(git rev-parse --absolute-git-dir)
readonly SQUASH_STAMP="$git_dir/squash-agentmsg.reviewed"
readonly DESC_STAMP="$git_dir/pr-agentdesc.reviewed"

die() {
  printf 'squash-merge: %s\n' "$1" >&2
  exit 1
}

step() { printf '\n--- %s\n' "$1"; }

command -v gh >/dev/null 2>&1 || die "gh is not installed"
gh auth status >/dev/null 2>&1 || die "gh is not authenticated"

branch=$(git rev-parse --abbrev-ref HEAD)
number=${1:-}
if [ -z "$number" ]; then
  number=$(gh pr list --head "$branch" --state open --json number --jq '.[0].number' 2>/dev/null || true)
  [ -n "$number" ] || die "no open pull request for ${branch}. Pass a number explicitly."
fi

# --- gate 1: the message exists and belongs to this pull request -----

step "checking ${SQUASH_DRAFT}"
[ -s "$SQUASH_DRAFT" ] || die "no squash message drafted. Run squash-message.sh first."

subject=$(head -1 "$SQUASH_DRAFT")
drafted_for=$(printf '%s' "$subject" | sed -n 's/.*(#\([0-9][0-9]*\))[[:space:]]*$/\1/p')
[ "$drafted_for" = "$number" ] ||
  die "${SQUASH_DRAFT} was drafted for #${drafted_for:-unknown}, not #${number}."
printf 'drafted for #%s\n' "$number"

# --- gate 2: the review signature ------------------------------------

step "checking the review signature"
digest() {
  if command -v sha256sum >/dev/null 2>&1; then
    sha256sum "$1" | cut -d' ' -f1
  else
    shasum -a 256 "$1" | cut -d' ' -f1
  fi
}

[ -f "$SQUASH_STAMP" ] ||
  die "codex-review-squash-message has not cleared this message. Delegate that
review, resolve its findings, and stamp its exact PASS before retrying."
[ "$(sed -n 's/^draft=//p' "$SQUASH_STAMP")" = "$(digest "$SQUASH_DRAFT")" ] ||
  die "${SQUASH_DRAFT} changed after codex-review-squash-message signed off.
Review it again and stamp the new exact PASS before retrying."
reviewed_head=$(sed -n 's/^head=//p' "$SQUASH_STAMP")
[ -n "$reviewed_head" ] || die "the review stamp names no pull request head. Review again."
printf 'signed at PR head %s\n' "$reviewed_head"

# --- gate 3: the commit-msg linters ----------------------------------
#
# The same four hooks a commit answers to. They run here rather than
# only in the skill body because this message never passes through
# git's commit-msg hook: GitHub writes the commit, not this machine.

step "running the commit-msg gates"
command -v mise >/dev/null 2>&1 || die "mise is not installed; the squash-message gate cannot run."
mise task info lint-squash-msg >/dev/null 2>&1 ||
  die "mise run lint-squash-msg is absent; the squash-message gate cannot run."
mise run lint-squash-msg ||
  die "the squash message fails the commit-msg gates. Fix it, review it again, retry."

# --- gate 4: the pull request is actually mergeable -------------------

step "checking #${number}"
readiness=$(gh pr view "$number" \
  --json state,isDraft,mergeable,mergeStateStatus,reviewDecision,headRefName,baseRefName,headRefOid,isCrossRepository \
  --jq '[.state, (.isDraft | tostring), .mergeable, .mergeStateStatus, (if .reviewDecision == "" then "NONE" else .reviewDecision end), .headRefName, .baseRefName, .headRefOid, (.isCrossRepository | tostring)] | @tsv') ||
  die "cannot read pull request #${number}."
IFS=$(printf '\t') read -r state is_draft mergeable merge_state review_decision head_ref base_ref head_oid cross_repo <<EOF
$readiness
EOF
[ "$state" = OPEN ] || die "#${number} is ${state}, not OPEN."
[ "$is_draft" = false ] || die "#${number} is a draft. Mark it ready before merging."
[ "$mergeable" = MERGEABLE ] || die "#${number} is not mergeable (${mergeable})."
[ "$merge_state" = CLEAN ] || die "#${number} is not ready to merge (${merge_state})."
case $review_decision in
APPROVED | NONE) ;;
*) die "#${number} review decision is ${review_decision}, not approved." ;;
esac
case $cross_repo in
true | false) ;;
*) die "cannot determine whether #${number} comes from a fork; branch cleanup is unsafe." ;;
esac
[ "$head_oid" = "$reviewed_head" ] ||
  die "#${number} moved from reviewed head ${reviewed_head} to ${head_oid}. Review again."

rollup=$(gh pr view "$number" --json statusCheckRollup \
  --jq '.statusCheckRollup[]? | (.conclusion // .state // "PENDING")' 2>/dev/null || true)
bad=$(printf '%s\n' "$rollup" | grep -c -E '^(FAILURE|TIMED_OUT|CANCELLED|ACTION_REQUIRED|ERROR)$' || true)
pending=$(printf '%s\n' "$rollup" | grep -c -E '^(PENDING|IN_PROGRESS|QUEUED|EXPECTED|WAITING)$' || true)
[ "$bad" = "0" ] || die "#${number} has ${bad} failing check(s). Hand it to the fix-pr skill."
[ "$pending" = "0" ] ||
  die "#${number} has ${pending} check(s) still running. Wait through the watch-pr skill."
printf 'open, ready, and green\n'

# --- merge -----------------------------------------------------------

body=$(awk 'NR > 1' "$SQUASH_DRAFT" | awk 'NF { seen = 1 } seen')

step "squashing #${number} into ${base_ref}"
gh pr merge "$number" --squash --match-head-commit "$head_oid" --subject "$subject" --body "$body"

# --- clean up --------------------------------------------------------

step "cleaning up"

# The drafts describe a pull request that no longer exists. Removed
# rather than emptied, so a stale read cannot carry them forward.
rm -f "$SQUASH_DRAFT" "$DESC_DRAFT" "$SQUASH_STAMP" "$DESC_STAMP"
printf 'removed %s and %s\n' "$SQUASH_DRAFT" "$DESC_DRAFT"

# The remote branch goes; the local one may be the branch this worktree
# stands on, and deleting that would strand the session. Say so instead.
if [ "$cross_repo" = false ] && git ls-remote --exit-code --heads origin "$head_ref" >/dev/null 2>&1; then
  git push origin --delete "$head_ref" >/dev/null 2>&1 &&
    printf 'deleted origin/%s\n' "$head_ref" ||
    printf 'could not delete origin/%s; a ruleset may protect it\n' "$head_ref"
fi

git fetch --quiet origin "$base_ref" 2>/dev/null || true
if [ "$cross_repo" = true ]; then
  printf 'left fork branch %s untouched\n' "$head_ref"
elif [ "$branch" = "$head_ref" ]; then
  printf '\nThis worktree still stands on %s, which has merged.\n' "$head_ref"
  printf 'Switch to %s before deleting it, or drop the whole worktree.\n' "$base_ref"
elif git rev-parse --verify --quiet "refs/heads/$head_ref" >/dev/null; then
  git branch -D "$head_ref" >/dev/null 2>&1 &&
    printf 'deleted local %s\n' "$head_ref" || true
fi

step "done"
gh pr view "$number" --json url,state --template 'merged: {{.url}} ({{.state}})
'
