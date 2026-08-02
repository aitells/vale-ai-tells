#!/usr/bin/env bash
# preflight — gather every fact the rebase skill needs before it moves
# the branch.
#
# The rebase SKILL.md inlines this through the !`...` preprocessor, so it
# runs once before the agent reads the skill body. The base decision that
# opens the workflow is already computed, and so is the answer to the
# question that decides everything after it: which paths this rebase is
# going to stop on.
#
# Output is plain text under `== section ==` headers, each self-contained
# so a partially-read report still answers something. Nothing here
# mutates the repository or the index. The one network call fetches the
# base branch; REBASE_PREFLIGHT_FETCH=0 skips it.
set -euo pipefail

# --- environment hardening -------------------------------------------
# The agent reads this output, so the operator's preferences must not
# change its shape. LC_ALL pins collation, which matters more here than
# in most of these scripts: the sorted-union classification downstream
# rests on sort order, and a UTF-8 locale orders these files differently
# from the C locale the files were written under.
export LC_ALL=C
export GH_PAGER=cat
export PYTHONUTF8=1
unset CDPATH GH_REPO GH_HOST GREP_OPTIONS
IFS=$(printf ' \t\n')

# gitr runs git for output this script parses, with every formatting
# knob pinned. log.showSignature is the one that matters most: it
# prepends a verification line per commit to stdout, ahead of the format
# string, so a --oneline listing silently becomes two lines per commit
# and any head -n cap shows half a branch as though it were all of it.
#
# Plain `git` stays available on purpose. Config reads and the fetch need
# the operator's real configuration.
gitr() {
  command git --no-pager \
    -c log.showSignature=false \
    -c color.ui=false -c color.diff=false -c color.status=false \
    -c core.quotePath=false \
    -c diff.noprefix=false -c diff.mnemonicPrefix=false \
    -c diff.renames=true -c diff.context=3 \
    "$@"
}

readonly DO_FETCH=${REBASE_PREFLIGHT_FETCH:-1}
readonly FETCH_TIMEOUT=${REBASE_PREFLIGHT_FETCH_TIMEOUT:-10}
readonly COMMIT_CAP=${REBASE_PREFLIGHT_COMMIT_CAP:-40}

section() { printf '\n== %s ==\n' "$1"; }
none() { printf '(none)\n'; }

# run_with_timeout bounds a command that touches the network. macOS ships
# no coreutils `timeout`, so this uses perl's alarm, which is present on
# every macOS and CI image this repo targets. Without perl the command
# runs unbounded rather than not at all.
run_with_timeout() {
  local secs=$1
  shift
  if command -v perl >/dev/null 2>&1; then
    perl -e 'alarm shift; exec @ARGV' "$secs" "$@"
  else
    "$@"
  fi
}

# ahead_behind prints "ahead N, behind M" for $1 relative to $2, or a
# marker when either ref is missing.
ahead_behind() {
  local left=$1 right=$2 counts
  if ! git rev-parse --verify --quiet "$left" >/dev/null ||
    ! git rev-parse --verify --quiet "$right" >/dev/null; then
    printf 'unknown (missing ref)\n'
    return
  fi
  counts=$(git rev-list --left-right --count "$right...$left")
  printf 'ahead %s, behind %s\n' "${counts##*[[:space:]]}" "${counts%%[[:space:]]*}"
}

# behind_count prints just the behind count of $1 relative to $2, for the
# arithmetic the base decision needs.
behind_count() {
  local counts
  counts=$(git rev-list --left-right --count "$2...$1" 2>/dev/null) || {
    printf '0\n'
    return
  }
  printf '%s\n' "${counts%%[[:space:]]*}"
}

root=$(git rev-parse --show-toplevel)
cd "$root"
branch=$(git rev-parse --abbrev-ref HEAD)

default_branch=main
if remote_head=$(git symbolic-ref --quiet refs/remotes/origin/HEAD 2>/dev/null); then
  default_branch=${remote_head##*/}
elif ! git rev-parse --verify --quiet refs/heads/main >/dev/null &&
  git rev-parse --verify --quiet refs/heads/master >/dev/null; then
  default_branch=master
fi

section "worktree"
printf 'root:     %s\n' "$root"
printf 'branch:   %s\n' "$branch"
case $root in
*/.claude/worktrees/*) printf 'layout:   agent worktree under .claude/worktrees\n' ;;
*) printf 'layout:   primary checkout\n' ;;
esac
printf 'head:     %s\n' "$(git rev-parse --short HEAD)"
upstream=$(git rev-parse --abbrev-ref --symbolic-full-name '@{upstream}' 2>/dev/null || echo none)
printf 'upstream: %s\n' "$upstream"

# A rebase already in progress changes which step of this skill applies:
# the workflow resumes at the conflict rather than starting one.
git_dir=$(git rev-parse --absolute-git-dir)
in_progress=none
if [ -d "$git_dir/rebase-merge" ] || [ -d "$git_dir/rebase-apply" ]; then
  in_progress="rebase (this skill resumes it at step 3; do not start another)"
elif [ -f "$git_dir/MERGE_HEAD" ]; then
  in_progress="merge (finish or abort it before rebasing)"
elif [ -f "$git_dir/CHERRY_PICK_HEAD" ]; then
  in_progress="cherry-pick (finish or abort it before rebasing)"
fi
printf 'in progress: %s\n' "$in_progress"

if [ "$branch" = "$default_branch" ]; then
  printf 'NOTE: HEAD is the default branch itself. There is nothing to replay;\n'
  printf '      a fast-forward pull is the operation you want, not a rebase.\n'
fi

section "rebase base"
fetch_state=skipped
if [ "$DO_FETCH" = "1" ]; then
  if run_with_timeout "$FETCH_TIMEOUT" git fetch --quiet origin "$default_branch" 2>/dev/null; then
    fetch_state=ok
  else
    fetch_state="failed (origin counts below may be stale)"
  fi
fi
printf 'fetch:  %s\n' "$fetch_state"
printf 'default branch: %s\n' "$default_branch"
printf '%s vs origin/%s:  %s\n' "$default_branch" "$default_branch" \
  "$(ahead_behind "refs/heads/$default_branch" "refs/remotes/origin/$default_branch")"
printf '%s vs %s:  %s\n' "$branch" "$default_branch" \
  "$(ahead_behind HEAD "refs/heads/$default_branch")"
printf '%s vs origin/%s:  %s\n' "$branch" "$default_branch" \
  "$(ahead_behind HEAD "refs/remotes/origin/$default_branch")"

# Local main is only a safe rebase target when it carries everything
# origin has. One commit behind and rebasing onto it replays the branch
# over a stale base, which shows up later as a needless second rebase.
# This is the same decision the commit skill's preflight makes, and it
# has to reach the same answer, because either skill may be the one that
# moves the branch.
local_behind=$(behind_count "refs/heads/$default_branch" "refs/remotes/origin/$default_branch")
if [ "$local_behind" = "0" ]; then
  base="$default_branch"
  printf 'recommended base: %s\n' "$base"
  printf 'reason: local %s carries everything origin/%s has\n' "$default_branch" "$default_branch"
else
  base="origin/$default_branch"
  printf 'recommended base: %s\n' "$base"
  printf 'reason: local %s is %s commit(s) behind origin/%s\n' \
    "$default_branch" "$local_behind" "$default_branch"
fi

if ! git rev-parse --verify --quiet "$base" >/dev/null; then
  printf 'ERROR: %s does not resolve. Stop and tell the operator.\n' "$base"
  base=""
fi

section "commits to replay"
if [ -n "$base" ]; then
  replay=$(gitr log --oneline --no-decorate "$base..HEAD" 2>/dev/null || true)
  if [ -z "$replay" ]; then
    printf '(none — the branch carries nothing %s does not already have)\n' "$base"
  else
    count=$(printf '%s\n' "$replay" | wc -l | tr -d ' ')
    printf 'count: %s\n' "$count"
    printf '%s\n' "$replay" | head -n "$COMMIT_CAP"
    if [ "$count" -gt "$COMMIT_CAP" ]; then
      printf '(%s more, capped at %s)\n' "$((count - COMMIT_CAP))" "$COMMIT_CAP"
    fi
  fi
  printf '\nwhat the base added since the branch left it:\n'
  incoming=$(gitr log --oneline --no-decorate "HEAD..$base" 2>/dev/null || true)
  if [ -n "$incoming" ]; then
    printf '%s\n' "$incoming" | head -n "$COMMIT_CAP"
  else
    none
  fi
fi

section "working tree state"
staged=$(gitr diff --no-ext-diff --cached --name-only)
unstaged=$(gitr diff --no-ext-diff --name-only)
untracked=$(git ls-files --others --exclude-standard)
printf 'staged:\n'
if [ -n "$staged" ]; then printf '%s\n' "$staged"; else none; fi
printf 'unstaged:\n'
if [ -n "$unstaged" ]; then printf '%s\n' "$unstaged"; else none; fi
printf 'untracked:\n'
if [ -n "$untracked" ]; then printf '%s\n' "$untracked"; else none; fi
if [ -n "$staged$unstaged" ]; then
  printf '\nThe tree is dirty. --autostash carries it across, and start-rebase.sh\n'
  printf 'passes that flag. Never a bare git stash pop: worktrees share one\n'
  printf 'stash stack. Where the work is worth keeping across an abort as well,\n'
  printf 'park it in a throwaway wip commit first (see the worktree rules).\n'
fi

# Predicted conflicts. merge-tree performs the merge in memory and
# touches neither the index nor the worktree, so this costs nothing and
# can run before the operator has committed to anything.
#
# It merges the two tips rather than replaying each commit, so it is an
# approximation in one direction: a rebase can stop on a commit whose
# conflict a later commit on the same branch would have undone, and
# merge-tree never sees that intermediate state. Every path it names is
# a real conflict; the list can be short, never wrong.
section "predicted conflicts"
if [ -n "$base" ]; then
  if predicted=$(git merge-tree --write-tree --name-only "$base" HEAD 2>/dev/null); then
    printf 'clean: merge-tree replayed the branch onto %s with no conflict\n' "$base"
    printf '(a per-commit replay can still stop; this is a lower bound)\n'
  else
    # First line is the tree oid; the conflicted paths follow, and an
    # informational block follows those after a blank line.
    printf 'merge-tree reports conflicts on:\n'
    printf '%s\n' "$predicted" | awk 'NR > 1 { if ($0 == "") exit; print }'
    printf '\nclassify each one with the resolve-rebase-conflicts skill once the\n'
    printf 'rebase actually stops. These names are the preview, not the stop.\n'
  fi
fi

section "config affecting this rebase"
conflict_style=$(git config --get merge.conflictStyle || echo merge)
printf 'merge.conflictStyle: %s' "$conflict_style"
case $conflict_style in
diff3 | zdiff3) printf '  (three-way markers: a ||||||| base section is present)\n' ;;
*) printf '  (two-way markers: no base section)\n' ;;
esac
rerere=$(git config --get rerere.enabled || echo unset)
printf 'rerere.enabled: %s' "$rerere"
if [ "$rerere" = "true" ]; then
  printf '  (git may replay a recorded resolution and stage it silently;\n'
  printf '                       every such path is unverified until something reads it)\n'
else
  printf '\n'
fi
printf 'rebase.updateRefs: %s  (start-rebase.sh pins this to false)\n' \
  "$(git config --get rebase.updateRefs || echo unset)"
printf 'rebase.autoSquash: %s  (start-rebase.sh pins this to false)\n' \
  "$(git config --get rebase.autoSquash || echo unset)"
printf 'rebase.autostash:  %s  (start-rebase.sh passes --autostash regardless)\n' \
  "$(git config --get rebase.autostash || echo unset)"
# Left to the operator rather than pinned. Dropping a commit is a
# content decision, and this workflow has no business making it
# silently. Unset means drop, which is git's own default and the reason
# verify-rebase.sh compares the branch against its pre-rebase self.
printf 'rebase.empty:      %s  (unset means git drops a commit the replay emptied,\n' \
  "$(git config --get rebase.empty || echo unset)"
printf '                          without stopping; the range-diff at the end is what shows it)\n'

section "gates"
if command -v just >/dev/null 2>&1; then
  summary=$(just --summary 2>/dev/null || true)
  for recipe in check lint test lint-markdown-wrap; do
    if printf '%s\n' "$summary" | tr ' ' '\n' | grep -qx "$recipe"; then
      printf 'just %-20s present\n' "$recipe"
    else
      printf 'just %-20s absent\n' "$recipe"
    fi
  done
else
  printf 'just: not installed — the post-rebase verification has nothing to run\n'
fi

# A rebase replays commits that each passed the hooks in isolation. What
# it produces is a tree none of them ever saw, which is the failure the
# verification step at the end of this skill exists to catch.
section "paths this rebase touches on both sides"
if [ -n "$base" ]; then
  merge_base=$(git merge-base "$base" HEAD 2>/dev/null || true)
  if [ -n "$merge_base" ]; then
    ours=$(gitr diff --no-ext-diff --name-only "$merge_base" "$base")
    theirs=$(gitr diff --no-ext-diff --name-only "$merge_base" HEAD)
    both=$(printf '%s\n%s\n' "$ours" "$theirs" | sed '/^$/d' | sort | uniq -d)
    if [ -n "$both" ]; then
      printf '%s\n' "$both"
      printf '\nEvery path above changed on the base and on the branch. Not all of\n'
      printf 'them conflict, and the ones that do not are the interesting case:\n'
      printf 'two edits that merge cleanly can still contradict each other.\n'
    else
      none
    fi
  fi
fi
