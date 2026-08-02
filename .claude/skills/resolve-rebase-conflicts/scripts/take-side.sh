#!/usr/bin/env bash
# take-side — resolve a conflict by taking one whole side, named the way
# a person thinks about it.
#
# `git checkout --ours` during a rebase takes the branch being replayed
# onto, and `--theirs` takes the commit being replayed. That is inverted
# from what the words suggest to anyone who has not just read the
# manual, because a rebase checks out the upstream and replays your work
# onto it, so your work is the side arriving. The mistake it produces is
# silent: the file resolves, the rebase continues, and a commit lands
# carrying the opposite of what was meant.
#
# This takes `base-side` and `replayed-side` instead, prints which
# commit each one is before acting, and translates to the stage number
# rather than the flag. Stage 2 is the base side and stage 3 is the
# replayed side, which is the one mapping in this area that never moves.
#
# Taking a whole side is right for a generated file, where merging two
# versions of machine output means nothing, and for a delete/modify
# where the decision is which intent wins. It is wrong wherever both
# sides carry work that has to survive, and this script cannot tell the
# difference. That judgement is the caller's.
#
# Usage: take-side.sh <path> <base-side|replayed-side>
# Exit:  0 resolved and staged, 1 refused.
set -euo pipefail

# --- environment hardening -------------------------------------------
# The agent reads this output, so the operator's preferences must not
# change its shape.
export LC_ALL=C
export PYTHONUTF8=1
unset CDPATH GREP_OPTIONS
IFS=$(printf ' \t\n')

gitr() {
  command git --no-pager \
    -c log.showSignature=false \
    -c color.ui=false -c color.diff=false -c color.status=false \
    -c core.quotePath=false \
    -c diff.noprefix=false -c diff.mnemonicPrefix=false \
    -c diff.renames=true -c diff.context=3 \
    "$@"
}

refuse() {
  printf 'take-side: %s\n' "$1" >&2
  exit 1
}

path=${1:-}
side=${2:-}
[ -n "$path" ] && [ -n "$side" ] ||
  refuse "usage: take-side.sh <path> <base-side|replayed-side>"

case $side in
base-side) stage=2 ;;
replayed-side) stage=3 ;;
ours | theirs)
  refuse "ours and theirs are the two words this script exists to avoid. During a
rebase they mean the opposite of what they suggest. Say which side you
want: base-side (what the branch is replayed onto) or replayed-side (the
commit being replayed)."
  ;;
*) refuse "unknown side '${side}'. Use base-side or replayed-side." ;;
esac

root=$(git rev-parse --show-toplevel)
cd "$root"
git_dir=$(git rev-parse --absolute-git-dir)

[ -d "$git_dir/rebase-merge" ] ||
  refuse "no rebase in progress under the merge backend."

stages=$(git ls-files -u -- "$path" | awk '{ printf "%s", $3 }')
[ -n "$stages" ] || refuse "$path is not unmerged."

stopped=$(tr -d '\n' <"$git_dir/rebase-merge/stopped-sha" 2>/dev/null || true)
onto=$(tr -d '\n' <"$git_dir/rebase-merge/onto" 2>/dev/null || true)

printf 'base-side     = %s\n' \
  "$(gitr log -1 --format='%h %s' "$onto" 2>/dev/null || printf 'the rebase target')"
printf 'replayed-side = %s\n' \
  "$(gitr log -1 --format='%h %s' "$stopped" 2>/dev/null || printf 'the commit being replayed')"
printf 'taking: %s (stage %s) for %s\n\n' "$side" "$stage" "$path"

case $stages in
*"$stage"*) ;;
*)
  # The chosen side has no version of this path, which means that side
  # deleted it. Taking that side is a deletion, and saying so plainly
  # beats writing an empty file and calling it a resolution.
  printf 'The %s has no version of this path: that side deleted it.\n' "$side"
  printf 'Taking it therefore means deleting the file.\n\n'
  git rm --quiet -- "$path"
  printf 'deleted and staged\n'
  exit 0
  ;;
esac

git cat-file blob ":$stage:$path" >"$path"
git add -- "$path"

printf 'staged %s lines from the %s\n' "$(wc -l <"$path" | tr -d ' ')" "$side"

declared=$(git check-attr rebase-resolve -- "$path" | sed 's/.*: //')
if [ "$declared" = regenerate ]; then
  printf '\nThis path is declared rebase-resolve=regenerate, so what was just staged\n'
  printf 'is a placeholder. Run its generator once the rebase finishes and commit\n'
  printf 'what changes. verify-rebase.sh names the path again at that point.\n'
fi
