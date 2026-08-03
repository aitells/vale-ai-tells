#!/usr/bin/env bash
# resolve-union — settle an append-only sorted file by taking the union
# of both sides, and prove afterwards that is what happened.
#
# A word list, a vocabulary file, an allowlist: two branches each append
# a few lines, both append near the same place, and the file conflicts
# on nearly every rebase. There is no judgement in it. The answer is
# every line either side has, sorted, once each, and an operator asked
# to confirm that is being asked to rubber-stamp arithmetic.
#
# What makes it safe to automate is the condition, not the file name.
# conflict_shape.py refuses unless all three versions are sorted and
# unique and neither side removed a line, and this script refuses
# whatever that refuses. A file that stops meeting those conditions
# stops being resolved here, which is what keeps a name-based shortcut
# from silently outliving the property it assumed.
#
# The check after the write is not ceremony. It re-derives the answer
# from the index stages, independently of what produced the file, and
# compares. A resolution that lost a line fails here rather than in a
# lint run three commits later.
#
# Usage: resolve-union.sh <path> [path ...]
# Exit:  0 every path resolved and staged, 1 at least one refused.
set -euo pipefail

# --- environment hardening -------------------------------------------
# LC_ALL pins the collation this whole resolution rests on: the file is
# sorted under the C locale, and writing it back sorted under another
# would reorder lines nobody touched.
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

[ "$#" -gt 0 ] || {
  printf 'usage: resolve-union.sh <path> [path ...]\n' >&2
  exit 1
}

root=$(git rev-parse --show-toplevel)
cd "$root"
git_dir=$(git rev-parse --absolute-git-dir)

[ -d "$git_dir/rebase-merge" ] || {
  printf 'resolve-union: no rebase in progress under the merge backend.\n' >&2
  exit 1
}

scratch=$(mktemp -d)
trap 'rm -rf "$scratch"' EXIT

failed=0
for path in "$@"; do
  printf '== %s ==\n' "$path"

  stages=$(git ls-files -u -- "$path" | awk '{ printf "%s", $3 }')
  if [ "$stages" != "123" ]; then
    printf 'refused: stages present are "%s", not all three. A union needs the\n' "${stages:-none}"
    printf 'common ancestor to tell an addition from a deletion.\n\n'
    failed=1
    continue
  fi

  for stage in 1 2 3; do
    git cat-file blob ":$stage:$path" >"$scratch/$stage"
  done

  declared=$(git check-attr rebase-resolve -- "$path" | sed 's/.*: //')
  # Exit 3 is the refusal, and every other nonzero status is the tool
  # breaking. Collapsing the two would report a traceback mid-rebase as a
  # routine "read this one yourself", which is the wrong instruction and
  # hides the defect that produced it.
  set +e
  DECLARED="$declared" uv run --script "${BASH_SOURCE%/*}/conflict_shape.py" \
    union "$path" "$scratch/1" "$scratch/2" "$scratch/3" >"$scratch/out"
  shape=$?
  set -e
  case "$shape" in
  0) ;;
  3)
    printf 'Resolve this one by reading it. classify-conflicts.sh prints what each\n'
    printf 'side changed.\n\n'
    failed=1
    continue
    ;;
  *)
    printf 'conflict_shape.py failed with status %s, which is not a verdict about\n' "$shape"
    printf 'this file. Stop and fix the tool; do not continue the rebase.\n\n'
    exit 1
    ;;
  esac

  cp "$scratch/out" "$path"

  # The proof. Re-derived from the index stages rather than from
  # anything the writer above kept in hand, so a bug in the writer shows
  # up as a mismatch instead of agreeing with itself.
  set +e
  python3 - "$path" "$scratch/2" "$scratch/3" <<'PY'
import pathlib
import sys

written, base_f, replayed_f = (pathlib.Path(a) for a in sys.argv[1:4])


def lines(p):
    data = p.read_bytes()
    out = data.split(b"\n")
    if data.endswith(b"\n"):
        out.pop()
    return out


got = lines(written)
base, replayed = lines(base_f), lines(replayed_f)
want = set(base) | set(replayed)

problems = []
if set(got) != want:
    missing = sorted(want - set(got))
    extra = sorted(set(got) - want)
    if missing:
        problems.append(f"{len(missing)} line(s) present on a side and missing from the result")
    if extra:
        problems.append(f"{len(extra)} line(s) in the result that neither side had")
if len(set(got)) != len(got):
    problems.append(f"{len(got) - len(set(got))} duplicate line(s)")
if got != sorted(got):
    problems.append("the result is not sorted under the C collation")

if problems:
    sys.stderr.write("resolve-union: the written file is not the union:\n")
    for p in problems:
        sys.stderr.write(f"  {p}\n")
    sys.exit(1)

both = len(set(base) & set(replayed))
print(f"  union verified: {len(got)} lines, no duplicates, sorted")
print(f"  base-side {len(base)} lines, replayed-side {len(replayed)} lines, {both} in common")
PY
  verified=$?
  set -e
  if [ "$verified" -ne 0 ]; then
    printf 'The file on disk is wrong. It has not been staged. Do not continue the\n'
    printf 'rebase until this is understood.\n\n'
    failed=1
    continue
  fi

  git add -- "$path"
  printf '  staged\n\n'
done

if [ "$failed" = 1 ]; then
  printf 'At least one path was refused. The rest are staged.\n'
  exit 1
fi

printf 'All given paths resolved and staged. Remaining conflicts:\n'
remaining=$(gitr diff --no-ext-diff --name-only --diff-filter=U)
if [ -n "$remaining" ]; then printf '%s\n' "$remaining"; else printf '(none)\n'; fi
