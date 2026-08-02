#!/usr/bin/env bash
# continue-rebase — advance a stopped rebase, after checking the two
# things git will not check for you.
#
# git refuses to continue while a path is unmerged, and that is the only
# refusal it makes. Stage a file with `<<<<<<<` still in it and the
# rebase continues happily, writing the markers into a commit that then
# has to be found and unpicked later. This script reads the staged
# content first, so that commit never gets made.
#
# The second check is on `--skip`. Skipping is right for exactly one
# situation: the replayed commit's change is already present, so
# applying it produces nothing. It is wrong for every other situation,
# where it discards a commit's work silently. `--skip-empty` proves the
# emptiness before it skips, rather than taking the caller's word.
#
# Usage: continue-rebase.sh [--skip-empty]
# Exit:  0 the rebase finished, 1 it stopped again, 2 it cannot advance
#        yet and the reason is printed.
set -euo pipefail

# --- environment hardening -------------------------------------------
# The agent reads this output, so the operator's preferences must not
# change its shape. The editor pins keep `git rebase --continue` from
# opening a message editor nothing here can answer.
export LC_ALL=C
export PYTHONUTF8=1
export GIT_EDITOR=true
export GIT_SEQUENCE_EDITOR=true
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
  printf 'continue-rebase: %s\n' "$1" >&2
  exit 2
}

skip_empty=0
case ${1:-} in
--skip-empty) skip_empty=1 ;;
"") ;;
*) refuse "unknown argument ${1}. Usage: continue-rebase.sh [--skip-empty]" ;;
esac

root=$(git rev-parse --show-toplevel)
cd "$root"
git_dir=$(git rev-parse --absolute-git-dir)

[ -d "$git_dir/rebase-merge" ] ||
  refuse "no rebase in progress under the merge backend. Nothing to continue."

unmerged=$(gitr diff --no-ext-diff --name-only --diff-filter=U)

if [ "$skip_empty" = 1 ]; then
  [ -z "$unmerged" ] ||
    refuse "paths are still unmerged, so this commit is not empty. Resolve them first:
$unmerged"
  if ! gitr diff --no-ext-diff --cached --quiet; then
    refuse "the index carries changes against HEAD, so this commit is not empty.
Skipping would discard them. Continue instead:

  bash .claude/skills/rebase/scripts/continue-rebase.sh"
  fi
  stopped=$(tr -d '\n' <"$git_dir/rebase-merge/stopped-sha" 2>/dev/null || true)
  printf 'Skipping a commit whose change is already present:\n'
  if [ -n "$stopped" ]; then
    gitr log -1 --format='  %h %s' "$stopped" 2>/dev/null || printf '  %s\n' "$stopped"
  fi
  printf '\nThe index matches HEAD, which is what makes this a drop rather than a\n'
  printf 'loss. The commit leaves the branch; its content stays, having arrived\n'
  printf 'through the base.\n\n'
else
  if [ -n "$unmerged" ]; then
    refuse "these paths are still unmerged:

$unmerged

Resolve them through the resolve-rebase-conflicts skill, stage each one,
then run this again."
  fi

  # The staged blob is what the commit will carry, so that is what gets
  # read. Checking the worktree file instead would miss a marker staged
  # earlier and edited away since, and would fire on a marker sitting in
  # an unstaged file the commit never touches.
  #
  # marker-scan.sh owns what counts as a marker and which files are
  # allowed to contain one, so this refusal and the report in
  # rebase-status.sh always agree about a given path.
  staged_paths=()
  while IFS= read -r path; do
    [ -n "$path" ] && staged_paths+=("$path")
  done <<EOF
$(gitr diff --no-ext-diff --cached --name-only)
EOF

  offenders=""
  if [ "${#staged_paths[@]}" -gt 0 ]; then
    offenders=$(bash "${BASH_SOURCE%/*}/marker-scan.sh" --staged "${staged_paths[@]}" || true)
  fi

  if [ -n "$offenders" ]; then
    refuse "conflict markers are staged in:

${offenders}
Continuing would commit them. Open each path, finish the resolution, and
stage it again. git itself will not stop you here, which is why this does."
  fi
fi

set +e
if [ "$skip_empty" = 1 ]; then
  output=$(command git -c core.editor=true rebase --skip 2>&1)
else
  output=$(command git -c core.editor=true rebase --continue 2>&1)
fi
status=$?
set -e

printf '%s\n' "$output"

replayed=$(printf '%s\n' "$output" | grep -E "^Resolved .* using previous resolution" || true)
if [ -n "$replayed" ]; then
  printf '\n== rerere replayed a recorded resolution ==\n'
  printf '%s\n' "$replayed"
  printf 'Nothing verified those. Read each path before continuing again.\n'
fi

if [ -d "$git_dir/rebase-merge" ]; then
  printf '\n== stopped again ==\n'
  if printf '%s\n' "$output" | grep -qiE 'is now empty|nothing to commit'; then
    printf 'git reports this commit as empty. Where that is because the base already\n'
    printf 'carries the change, drop it:\n\n'
    printf '  bash .claude/skills/rebase/scripts/continue-rebase.sh --skip-empty\n\n'
    printf 'Where it is because a resolution threw the commit away by accident, do\n'
    printf 'not skip. Abort and start again.\n'
  else
    printf 'Run rebase-status.sh for the detail on the next conflict.\n'
  fi
  exit 1
fi

if [ "$status" -ne 0 ]; then
  printf '\n== failed ==\n'
  printf 'git exited %s and left no rebase in progress. Report the message above.\n' "$status"
  exit 2
fi

printf '\n== finished ==\n'
printf 'The replay applied. Whether the result is correct is a separate\n'
printf 'question: run verify-rebase.sh next.\n'
