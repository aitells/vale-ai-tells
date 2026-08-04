#!/usr/bin/env bash
# verify-rebase — check what the rebase produced, not just that it
# applied.
#
# A rebase that ends without complaint has proved one thing: every
# commit applied. It has not proved that the commits still say what they
# said, and it has not proved that the result is a tree anything can
# build. Two failures live in that gap.
#
# A resolution can lose a hunk. The commit still applies, its message
# still describes the change it no longer makes, and nothing reports it.
# range-diff against the pre-rebase branch is what surfaces that: it
# pairs each old commit with its replayed self and shows what moved.
#
# A tree can break with no commit at fault. The base adds a gate, the
# branch adds a file that gate rejects, and neither side was red on its
# own. Only the combination fails, and the combination first exists
# here. So this reports which gates to run, and the workflow runs them.
#
# Read-only. It reports; the SKILL.md steps act.
#
# Usage: verify-rebase.sh [<pre-rebase-tip>]
# Exit:  0 nothing to flag, 1 something needs the agent's attention.
set -euo pipefail

# --- environment hardening -------------------------------------------
# The agent reads this output, so the operator's preferences must not
# change its shape.
export LC_ALL=C
export PYTHONUTF8=1
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

section() { printf '\n== %s ==\n' "$1"; }
none() { printf '(none)\n'; }

readonly RANGE_DIFF_CAP=${REBASE_VERIFY_RANGE_DIFF_LINES:-400}

root=$(git rev-parse --show-toplevel)
cd "$root"
git_dir=$(git rev-parse --absolute-git-dir)
flagged=0

if [ -d "$git_dir/rebase-merge" ] || [ -d "$git_dir/rebase-apply" ]; then
  printf 'A rebase is still in progress. Finish it before verifying anything.\n' >&2
  exit 1
fi

# The pre-rebase tip, in descending order of trust: the caller, the
# record start-rebase.sh left, then ORIG_HEAD. ORIG_HEAD is last because
# any later reset or merge overwrites it, and a wrong answer here reads
# as a branch full of unexplained changes.
before=${1:-}
base=""
if [ -z "$before" ] && [ -f "$git_dir/rebase-agent-state" ]; then
  before=$(awk -F= '$1 == "before" { print $2 }' "$git_dir/rebase-agent-state")
  base=$(awk -F= '$1 == "base_sha" { print $2 }' "$git_dir/rebase-agent-state")
  origin=state
fi
if [ -z "$before" ]; then
  before=$(git rev-parse --verify --quiet ORIG_HEAD || true)
  origin=ORIG_HEAD
else
  origin=${origin:-argument}
fi

section "what landed"
printf 'branch: %s\n' "$(git rev-parse --abbrev-ref HEAD)"
printf 'head:   %s\n' "$(git rev-parse --short HEAD)"
if [ -n "$base" ]; then
  printf 'base:   %s\n' "$(git rev-parse --short "$base" 2>/dev/null || printf '%s' "$base")"
  printf '\ncommits above the base:\n'
  gitr log --oneline --no-decorate "$base..HEAD" 2>/dev/null || true
else
  printf '\nrecent commits:\n'
  gitr log --oneline --no-decorate -10 2>/dev/null || true
fi

section "what the replay did to each commit"
if [ -z "$before" ]; then
  printf 'No pre-rebase tip to compare against (checked the start-rebase record\n'
  printf 'and ORIG_HEAD). Pass it as an argument to get this comparison.\n'
  flagged=1
else
  printf 'comparing against %s (%s)\n\n' "$(git rev-parse --short "$before")" "$origin"

  # Each range has to be spelled out. The three-dot shorthand takes the
  # merge base of the two tips, which after a rebase is the old base,
  # so the new range swallows every commit the base contributed and the
  # branch's own commits read as dropped and re-added. Naming
  # old-base..old-tip and new-base..new-tip pairs the patches properly.
  spec=""
  if [ -n "$base" ] && old_base=$(git merge-base "$before" "$base" 2>/dev/null); then
    # An empty range on either side is not something range-diff accepts,
    # and it is the loudest thing that can happen to a branch: every
    # commit emptied out during the replay and git dropped each one
    # without stopping. Saying so beats a usage message.
    old_count=$(git rev-list --count "$old_base..$before")
    new_count=$(git rev-list --count "$base..HEAD")
    if [ "$new_count" = 0 ]; then
      printf 'The branch now carries no commits of its own, where it carried %s\n' "$old_count"
      printf 'before. Every one applied as empty and git dropped it. Check the base\n'
      printf 'before concluding the work is gone: an identical change already on the\n'
      printf 'base produces exactly this.\n'
      flagged=1
    elif [ "$old_count" = 0 ]; then
      printf 'The pre-rebase branch carried no commits of its own, so there is\n'
      printf 'nothing to compare. The %s commit(s) here came from the base.\n' "$new_count"
    else
      spec="$old_base..$before $base..HEAD"
    fi
  else
    spec="$before...HEAD"
  fi
fi

if [ -n "${spec:-}" ]; then
  # --creation-factor is raised from its default of 60 because this is a
  # rebase rather than a rewritten series. A commit whose conflict
  # resolution changed a large fraction of a small patch falls outside
  # the default similarity window, and range-diff then reports it as one
  # commit dropped and another created, which reads as data loss where
  # none happened. The cost of raising it is the opposite mistake, a
  # genuinely dropped commit paired against an unrelated one, and the
  # per-commit diff printed below makes that visible.
  # shellcheck disable=SC2086  # spec is one or two ranges, deliberately split
  rd=$(git --no-pager -c color.ui=false range-diff --no-color \
    --creation-factor=90 $spec 2>/dev/null || true)
  if [ -z "$rd" ]; then
    printf 'range-diff produced nothing. The two ranges may share no merge base.\n'
    flagged=1
  elif [ "$(printf '%s\n' "$rd" | wc -l)" -le "$RANGE_DIFF_CAP" ]; then
    printf '%s\n' "$rd"
  else
    printf '%s\n' "$rd" | grep -E '^[ 0-9-]+: +[0-9a-f-]+ [!<>=]' || true
    printf '\n(the per-commit diff runs past %s lines. The pairing above is the\n' "$RANGE_DIFF_CAP"
    printf 'summary; a ! marks a commit whose content changed. Read those with\n'
    printf 'git range-diff %s.)\n' "$spec"
  fi
  printf '\nRead the pairing before the diff. = means the commit replayed\n'
  printf 'unchanged. ! means its content moved, which is expected where a\n'
  printf 'conflict was resolved and suspicious everywhere else. A < or > line\n'
  printf 'means a commit appeared or vanished.\n'
  if printf '%s\n' "$rd" | grep -qE '^ *[0-9]+: +[0-9a-f]+ <'; then
    printf '\nA commit from the old branch has no counterpart here. Either the rebase\n'
    printf 'dropped it, or a resolution changed it past recognition. Read the two\n'
    printf 'ranges and say which before going on.\n'
    flagged=1
  fi
fi

section "conflict markers anywhere in the tree"
# git grep narrows the tree to candidates cheaply; marker-scan.sh then
# decides which of those are real, so a file whose subject is conflict
# markers stops being reported here on every run forever.
candidates=()
while IFS= read -r path; do
  [ -n "$path" ] && candidates+=("$path")
done <<EOF
$(git grep -l -E '^(<<<<<<<|>>>>>>>|\|\|\|\|\|\|\|)( |$)' HEAD -- 2>/dev/null |
  sed 's/^HEAD://' || true)
EOF
markers=""
if [ "${#candidates[@]}" -gt 0 ]; then
  markers=$(bash "${BASH_SOURCE%/*}/marker-scan.sh" "${candidates[@]}" || true)
fi
if [ -n "$markers" ]; then
  printf '%s\n' "$markers"
  printf '\nThese are committed, not merely present in the worktree. Every one is a\n'
  printf 'resolution that never finished. Fix them before anything else.\n'
  flagged=1
else
  none
fi

section "regenerated files"
# A file the repository declares as generated was resolved by taking one
# side whole, which is right only because the generator is about to
# overwrite it. That second half is easy to forget once the rebase ends,
# so it gets named here.
#
# Only paths the rebase actually moved are worth naming. check-attr
# reads the whole list in one call, because a per-path call over a tree
# with a vendor directory is thousands of processes.
declared=""
if [ -n "$before" ]; then
  moved=$(gitr diff --no-ext-diff --name-only "$before" HEAD 2>/dev/null || true)
  if [ -n "$moved" ]; then
    declared=$(printf '%s\n' "$moved" |
      git check-attr --stdin rebase-resolve |
      awk -F': ' '$NF == "regenerate" { print $1 }')
  fi
fi
if [ -z "$declared" ]; then
  printf '(none the rebase touched)\n'
else
  printf '%s\n' "$declared"
  printf '\nEach of these is declared generated, so the resolution took one side\n'
  printf 'whole on the understanding that the generator would overwrite it. Run\n'
  printf 'the generator now and commit what it changes through the commit skill.\n'
  printf 'The repository names the generator; for a lockfile it is the install or\n'
  printf 'lock command that writes the file.\n'
  flagged=1
fi

section "working tree"
dirty=$(git status --porcelain=v1 2>/dev/null || true)
if [ -n "$dirty" ]; then
  printf '%s\n' "$dirty"
  printf '\nWork that --autostash carried across the rebase reappears here, and so\n'
  printf 'does anything a resolution left behind. Tell the two apart before\n'
  printf 'committing: the first was yours already, the second is new.\n'
else
  none
fi

section "gates to run"
# A rebase produces a tree no commit ever tested. Naming the tasks
# rather than running them keeps the output live in the agent's own
# terminal, where a failure arrives with its full context.
if command -v mise >/dev/null 2>&1; then
  ran=0
  for task in check lint; do
    if mise task info "$task" >/dev/null 2>&1; then
      printf 'mise run %s\n' "$task"
      ran=1
      break
    fi
  done
  [ "$ran" = 1 ] || printf '(no check or lint task in this repository)\n'
  printf '\nRun it against the tree as it now stands. The commits each passed the\n'
  printf 'hooks in isolation; this combination has never been tested.\n'
  printf '\nWhere the branch is long enough for a mid-history break to matter, the\n'
  printf 'thorough form runs the gate at every commit:\n\n'
  printf '  git -c rebase.updateRefs=false rebase --exec "mise run lint" %s\n' \
    "$(git rev-parse --short "${base:-HEAD}" 2>/dev/null || printf '<base>')"
else
  printf 'mise is not installed; there is nothing to run here.\n'
fi

exit "$flagged"
