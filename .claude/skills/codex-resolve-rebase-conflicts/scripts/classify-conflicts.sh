#!/usr/bin/env bash
# classify-conflicts — sort a stopped rebase's conflicts into the ones a
# script can settle and the ones that need a reader.
#
# Most conflicts in a repository of this shape are not disagreements.
# Two branches append to a sorted word list, and the union of both is the
# answer every time. A generated lockfile conflicts because it is
# regenerated wholesale, and either side does, because the generator
# overwrites it afterwards. Sending those to an operator, or to an agent
# reading markers by eye, is how a mechanical resolution acquires a
# chance of being wrong.
#
# So each path gets classified before anything edits it, and the
# classification is a claim with evidence printed beside it. A sorted
# union is claimed only where all three stages really are sorted and
# unique and neither side removed a line, because those are the
# conditions under which the union provably loses nothing.
#
# One inversion is worth knowing before reading any output here. During
# a rebase, "ours" is the base being replayed onto and "theirs" is the
# commit being replayed. That is backwards from every intuition about a
# branch, so this script names the sides `base-side` and `replayed-side`
# and never prints ours or theirs at all.
#
# Read-only. Nothing here stages or resolves anything.
#
# Usage: classify-conflicts.sh [path ...]     (default: every unmerged path)
# Exit:  0 classified, 1 no rebase in progress or nothing unmerged.
set -euo pipefail

# --- environment hardening -------------------------------------------
# LC_ALL matters more here than anywhere else in this toolchain: the
# sorted-union classification rests on sort order, and these files were
# written under the C collation. Judging them under a UTF-8 one would
# call a sorted file unsorted and quietly send a mechanical case to a
# human, or worse, the reverse.
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

readonly SIDE_DIFF_CAP=${RESOLVE_SIDE_DIFF_LINES:-60}

root=$(git rev-parse --show-toplevel)
cd "$root"
git_dir=$(git rev-parse --absolute-git-dir)

command -v uv >/dev/null 2>&1 || {
  printf 'classify-conflicts: uv is not installed.\n' >&2
  exit 1
}

if [ -d "$git_dir/rebase-apply" ]; then
  printf 'classify-conflicts: the apply rebase backend is not supported.\n' >&2
  exit 1
fi
if [ ! -d "$git_dir/rebase-merge" ]; then
  printf 'classify-conflicts: no merge-backend rebase is in progress.\n' >&2
  exit 1
fi

unmerged=$(gitr diff --no-ext-diff --name-only --diff-filter=U)
if [ "$#" -gt 0 ]; then
  unmerged=$(printf '%s\n' "$@")
fi
if [ -z "$unmerged" ]; then
  printf 'classify-conflicts: nothing is unmerged.\n' >&2
  exit 1
fi

scratch=$(mktemp -d)
trap 'rm -rf "$scratch"' EXIT

stopped=$(tr -d '\n' <"$git_dir/rebase-merge/stopped-sha" 2>/dev/null || true)
onto=$(tr -d '\n' <"$git_dir/rebase-merge/onto" 2>/dev/null || true)

printf '== sides ==\n'
printf 'base-side     = what the branch is being replayed onto'
[ -n "$onto" ] && printf '  (%s)' "$(gitr log -1 --format='%h %s' "$onto" 2>/dev/null || true)"
printf '\n'
printf 'replayed-side = the commit being replayed'
[ -n "$stopped" ] && printf '  (%s)' "$(gitr log -1 --format='%h %s' "$stopped" 2>/dev/null || true)"
printf '\n'
printf 'git calls these ours and theirs respectively, which is backwards from\n'
printf 'the usual reading. Nothing below uses those two words.\n'

while IFS= read -r path; do
  [ -n "$path" ] || continue
  printf '\n== %s ==\n' "$path"

  stages=$(git ls-files -u -- "$path" | awk '{ printf "%s", $3 }')
  case $stages in
  "")
    printf 'not unmerged. Either it never conflicted, or something already staged\n'
    printf 'a resolution for it. Where rerere is on, that is the likely cause, and\n'
    printf 'the staged content is a replay nothing has read.\n'
    continue
    ;;
  23)
    printf 'kind: add/add. Both sides created this path independently; there is no\n'
    printf 'common ancestor to merge against, so the whole file is the conflict.\n'
    ;;
  12)
    printf 'kind: delete/modify. The replayed commit deleted it; the base changed\n'
    printf 'it. Deciding needs the intent behind the delete, so this is not\n'
    printf 'mechanical. take-side.sh settles it once you know which way.\n'
    ;;
  13)
    printf 'kind: delete/modify. The base deleted it; the replayed commit changed\n'
    printf 'it. Same reading required.\n'
    ;;
  *) printf 'kind: content (both sides changed it)\n' ;;
  esac

  declared=$(git check-attr rebase-resolve -- "$path" | sed 's/.*: //')
  case $declared in
  regenerate)
    printf 'declared: rebase-resolve=regenerate\n'
    printf 'class: regenerate  (mechanical)\n'
    printf 'This file is generated, so neither side is authoritative and merging\n'
    printf 'them means nothing. Take one whole and let the generator rewrite it\n'
    printf 'once the rebase ends:\n\n'
    printf '  bash .agents/skills/codex-resolve-rebase-conflicts/scripts/take-side.sh %s base-side\n\n' "$path"
    printf 'verify-rebase.sh names this path again at the end so the regeneration\n'
    printf 'does not get forgotten.\n'
    continue
    ;;
  manual)
    printf 'declared: rebase-resolve=manual — never resolved mechanically here.\n'
    ;;
  union)
    printf 'declared: rebase-resolve=union\n'
    ;;
  esac

  # The three stages, extracted whole. Working from complete versions
  # rather than from the marker regions is what makes the checks below
  # provable: sortedness is a property of the file, and a line one side
  # removed is invisible inside a region that does not contain it.
  for stage in 1 2 3; do
    rm -f "$scratch/$stage"
    git cat-file blob ":$stage:$path" >"$scratch/$stage" 2>/dev/null || true
  done

  # classify mode has no refusal path, so any nonzero here is the tool
  # breaking rather than a verdict. Named explicitly so this call does not
  # rest on a property of the other mode.
  DECLARED="$declared" uv run --script "${BASH_SOURCE%/*}/conflict_shape.py" \
    classify "$path" "$scratch/1" "$scratch/2" "$scratch/3" || {
    printf 'conflict_shape.py failed with status %s while classifying %s.\n' "$?" "$path"
    exit 1
  }

  # For a genuine content conflict, what each side was trying to do is
  # the thing that settles it, and neither the markers nor the merged
  # file says. These two diffs do.
  if [ "$stages" != 23 ] && [ -s "$scratch/1" ]; then
    for side in 2:base-side 3:replayed-side; do
      stage=${side%%:*}
      label=${side#*:}
      [ -s "$scratch/$stage" ] || continue
      printf '\n  what %s changed, against the common ancestor:\n' "$label"
      d=$(gitr diff --no-ext-diff --no-index -- "$scratch/1" "$scratch/$stage" 2>/dev/null || true)
      body=$(printf '%s\n' "$d" | tail -n +5)
      if [ "$(printf '%s\n' "$body" | wc -l)" -le "$SIDE_DIFF_CAP" ]; then
        printf '%s\n' "$body" | sed 's/^/    /'
      else
        hint="git diff :1:$path :$stage:$path" # hygiene-ok: advice to print, not a call
        printf '    (%s lines. Read it with: %s)\n' \
          "$(printf '%s\n' "$body" | wc -l | tr -d ' ')" "$hint"
      fi
    done
  fi
done <<EOF
$unmerged
EOF

printf '\n== next ==\n'
printf 'Resolve every mechanical path with the script named beside it. Read the\n'
printf 'rest. Stage each resolved path, then advance the rebase with\n'
printf '.agents/skills/codex-rebase/scripts/continue-rebase.sh, which refuses to\n'
printf 'commit a staged file that still carries markers.\n'
