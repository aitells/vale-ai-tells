#!/usr/bin/env bash
# rebase-status — say where a stopped rebase actually is.
#
# `git status` during a rebase answers a different question than the one
# the workflow has. It says which files are unmerged; it does not say
# which commit stopped, how far through the replay that commit sits,
# what git staged without asking, or whether a resolution someone
# already made left conflict markers behind.
#
# Read-only. Nothing here stages, resolves, or advances anything.
#
# Usage: rebase-status.sh
# Exit:  0 stopped with conflicts to resolve, 1 no rebase in progress,
#        2 stopped for a reason other than a conflict.
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

section() { printf '\n== %s ==\n' "$1"; }
none() { printf '(none)\n'; }

root=$(git rev-parse --show-toplevel)
cd "$root"
git_dir=$(git rev-parse --absolute-git-dir)

if [ -d "$git_dir/rebase-apply" ]; then
  printf 'A rebase is in progress under the apply backend, which this workflow\n'
  printf 'does not drive. Finish it by hand or abort it.\n'
  exit 2
fi

if [ ! -d "$git_dir/rebase-merge" ]; then
  printf 'No rebase in progress.\n'
  exit 1
fi

state="$git_dir/rebase-merge"
read_state() { [ -f "$state/$1" ] && tr -d '\n' <"$state/$1" || printf '%s' "$2"; }

section "where"
head_name=$(read_state head-name unknown)
printf 'branch:  %s\n' "${head_name##refs/heads/}"
printf 'onto:    %s' "$(read_state onto unknown)"
onto=$(read_state onto "")
if [ -n "$onto" ]; then
  printf '  %s' "$(gitr log -1 --format='%h %s' "$onto" 2>/dev/null || true)"
fi
printf '\n'
printf 'progress: commit %s of %s\n' "$(read_state msgnum '?')" "$(read_state end '?')"

stopped=$(read_state stopped-sha "")
if [ -n "$stopped" ]; then
  printf '\nstopped applying:\n'
  gitr log -1 --format='  %h %s%n  author: %an' "$stopped" 2>/dev/null || printf '  %s\n' "$stopped"
  printf '\nwhat that commit changes, against its own parent:\n'
  gitr show --no-ext-diff --stat --format= "$stopped" 2>/dev/null | sed 's/^/  /' || true
else
  printf '\nNo stopped commit recorded. The rebase paused for an edit or break\n'
  printf 'instruction rather than a conflict; there may be nothing to resolve.\n'
fi

section "unmerged paths"
unmerged=$(gitr diff --no-ext-diff --name-only --diff-filter=U)
if [ -z "$unmerged" ]; then
  none
  printf '\nEvery path is resolved as far as the index is concerned. Advance with\n'
  printf 'continue-rebase.sh, which checks the staged content before it does.\n'
else
  # Stage presence tells the conflict kind apart before anything opens a
  # file. Stage 1 is the merge base, 2 the branch being replayed onto,
  # and 3 the commit being replayed. A missing stage 1 is an add/add, a
  # missing 2 or 3 is a delete/modify, and those resolve differently
  # from a plain content conflict.
  while IFS= read -r path; do
    [ -n "$path" ] || continue
    stages=$(git ls-files -u -- "$path" | awk '{ printf "%s", $3 }')
    kind="content"
    case $stages in
    23) kind="add/add (no common ancestor for this path)" ;;
    12) kind="delete/modify (the replayed commit deleted it)" ;;
    13) kind="delete/modify (the base deleted it)" ;;
    esac
    printf '%s\n  stages present: %s   kind: %s\n' "$path" "${stages:-none}" "$kind"
  done <<EOF
$unmerged
EOF
fi

# Anything staged that was never unmerged is a path git settled without
# asking. Where rerere is on, that is a recorded resolution replayed
# from an earlier rebase, and nothing has read it since.
section "staged without stopping"
staged=$(gitr diff --no-ext-diff --cached --name-only)
settled=$(printf '%s\n%s\n%s\n' "$staged" "$unmerged" "$unmerged" | sed '/^$/d' | sort | uniq -u)
if [ -z "$settled" ]; then
  none
else
  printf '%s\n' "$settled"
  if [ "$(git config --get rerere.enabled || echo false)" = "true" ]; then
    printf '\nrerere is enabled, so some of these may be resolutions replayed from a\n'
    printf 'recording made against different surrounding code. Read any path here\n'
    printf 'that the stopped commit also touches.\n'
  fi
fi

# A resolution that leaves markers behind is the failure this whole
# workflow is arranged to prevent, so it gets checked at every stop
# rather than only at the end. marker-scan.sh owns what counts as a
# marker, so this report and the refusal in continue-rebase.sh cannot
# disagree about a given file.
section "conflict markers in the worktree"
candidates=()
while IFS= read -r path; do
  [ -n "$path" ] && candidates+=("$path")
done <<EOF
$(printf '%s\n%s\n' "$unmerged" "$staged" | sed '/^$/d' | sort -u)
EOF
markers=""
if [ "${#candidates[@]}" -gt 0 ]; then
  markers=$(bash "${BASH_SOURCE%/*}/marker-scan.sh" "${candidates[@]}" || true)
fi
if [ -n "$markers" ]; then printf '%s\n' "$markers"; else none; fi

section "remaining after this commit"
if [ -f "$state/git-rebase-todo" ]; then
  todo=$(grep -vE '^(#|$)' "$state/git-rebase-todo" || true)
  if [ -n "$todo" ]; then printf '%s\n' "$todo"; else printf '(this is the last commit)\n'; fi
fi

section "next"
if [ -n "$unmerged" ]; then
  printf 'Hand these to the resolve-rebase-conflicts skill. It classifies each\n'
  printf 'path before anything edits it, and resolves the mechanical ones itself.\n'
else
  printf 'bash .claude/skills/rebase/scripts/continue-rebase.sh\n'
fi
