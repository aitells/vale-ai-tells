#!/usr/bin/env bash
# start-rebase — replay the branch onto a base under pinned settings,
# and report what happened in terms the workflow can act on.
#
# Three things make this a script rather than a command the agent types.
#
# The settings. rebase.updateRefs quietly moves other local branches that
# point into the replayed range, and rebase.autoSquash collapses a
# `fixup!` commit that earned its own review. Both are operator
# preferences that can be on without anyone here knowing, so both are
# pinned off. The editors are pinned to `true` because an agent cannot
# answer an editor that opens.
#
# The record. A rebase rewrites the branch, and afterwards nothing on
# disk remembers what it looked like before. ORIG_HEAD does until the
# next operation overwrites it, so the pre-rebase tip is written down
# here instead, and verify-rebase.sh reads it back to show what the
# replay did to each patch.
#
# The reading. git says what happened across stdout and stderr, mixed
# with progress noise, and the one line that matters most is easy to
# lose: rerere replaying a recorded resolution stages a file without
# stopping, and announces it in a single sentence.
#
# Usage: start-rebase.sh <base>
# Exit:  0 the rebase finished, 1 it stopped on a conflict, 2 it could
#        not start or failed outright.
set -euo pipefail

# --- environment hardening -------------------------------------------
# The agent reads this output, so the operator's preferences must not
# change its shape. The editor pins belong to the same idea: an operator
# with a graphical editor configured would otherwise hang this call.
export LC_ALL=C
export PYTHONUTF8=1
export GIT_EDITOR=true
export GIT_SEQUENCE_EDITOR=true
unset CDPATH GREP_OPTIONS
IFS=$' \t\n'

gitr() {
  command git --no-pager \
    -c log.showSignature=false \
    -c color.ui=false -c color.diff=false -c color.status=false \
    -c core.quotePath=false \
    -c diff.noprefix=false -c diff.mnemonicPrefix=false \
    -c diff.renames=true -c diff.context=3 \
    "$@"
}

die() {
  printf 'start-rebase: %s\n' "$1" >&2
  exit 2
}

base=${1:-}
[ -n "$base" ] || die "no base given. Pass the base preflight recommended: start-rebase.sh <base>"

root=$(git rev-parse --show-toplevel)
cd "$root"
git_dir=$(git rev-parse --absolute-git-dir)

if [ -d "$git_dir/rebase-merge" ] || [ -d "$git_dir/rebase-apply" ]; then
  die "a rebase is already in progress. Resume it with continue-rebase.sh, or abandon it with git rebase --abort."
fi
if [ -f "$git_dir/MERGE_HEAD" ] || [ -f "$git_dir/CHERRY_PICK_HEAD" ]; then
  die "a merge or cherry-pick is in progress. Finish or abort it first."
fi

git rev-parse --verify --quiet "$base^{commit}" >/dev/null ||
  die "$base does not resolve to a commit."

branch=$(git rev-parse --abbrev-ref HEAD)
[ "$branch" != HEAD ] || die "HEAD is detached. Check out the branch you mean to rebase."

before=$(git rev-parse HEAD)
base_sha=$(git rev-parse "$base")

if [ "$before" = "$base_sha" ]; then
  printf 'Nothing to do: %s is already at %s.\n' "$branch" "$base"
  exit 0
fi

# The state file outlives the rebase on purpose. verify-rebase.sh reads
# it to range-diff the branch against its pre-rebase self, which is the
# only view that shows a resolution having dropped a hunk.
printf 'branch=%s\nbase=%s\nbase_sha=%s\nbefore=%s\n' \
  "$branch" "$base" "$base_sha" "$before" >"$git_dir/rebase-agent-state"

printf 'Rebasing %s (%s) onto %s (%s).\n\n' \
  "$branch" "$(git rev-parse --short "$before")" "$base" "$(git rev-parse --short "$base_sha")"

# --autostash scopes the save to this rebase and never touches the
# shared stash stack, which is what makes it the sanctioned form here.
# One consequence worth knowing while resolving: the stashed work is not
# in the worktree during the conflict, and it reapplies only once the
# replay finishes.
set +e
output=$(
  command git \
    -c rebase.updateRefs=false \
    -c rebase.autoSquash=false \
    -c core.editor=true \
    rebase --autostash "$base" 2>&1
)
status=$?
set -e

printf '%s\n' "$output"

# rerere's one-line announcement is the whole notice that a resolution
# was replayed from a recording rather than made here. A recording can
# be stale, so a replayed path is a claim to check rather than a
# resolution to trust.
replayed=$(printf '%s\n' "$output" | grep -E "^Resolved .* using previous resolution" || true)
if [ -n "$replayed" ]; then
  printf '\n== rerere replayed a recorded resolution ==\n'
  printf '%s\n' "$replayed"
  printf 'Nothing verified those. Read each path before the rebase continues.\n'
fi

if [ -d "$git_dir/rebase-merge" ] || [ -d "$git_dir/rebase-apply" ]; then
  printf '\n== stopped ==\n'
  printf 'The rebase stopped. Run rebase-status.sh for the detail, then hand the\n'
  printf 'conflict to the resolve-rebase-conflicts skill.\n'
  exit 1
fi

if [ "$status" -ne 0 ]; then
  printf '\n== failed ==\n'
  printf 'git exited %s without leaving a rebase in progress, so the branch is\n' "$status"
  printf 'where it started. Report the message above rather than retrying.\n'
  exit 2
fi

after=$(git rev-parse HEAD)
printf '\n== finished ==\n'
printf 'before: %s\n' "$(git rev-parse --short "$before")"
printf 'after:  %s\n' "$(git rev-parse --short "$after")"
printf '\ncommits now on %s above %s:\n' "$branch" "$base"
gitr log --oneline --no-decorate "$base_sha..HEAD" || true

# An autostash that conflicts on the way back leaves the tree in a state
# no commit describes, and git says so in one line among many.
if printf '%s\n' "$output" | grep -qE 'Applying autostash resulted in conflicts'; then
  printf '\n== autostash conflicted ==\n'
  printf 'The rebase finished, but the uncommitted work did not reapply cleanly.\n'
  printf 'It is kept in the stash; git named the entry above. Resolve the tree,\n'
  printf 'then drop that entry by its own name, never a bare git stash pop.\n'
fi

printf '\nThe replay applied. Whether the result is correct is a separate\n'
printf 'question: run verify-rebase.sh next.\n'
