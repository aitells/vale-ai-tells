#!/usr/bin/env bash
# marker-scan — find conflict markers in a set of paths, and know which
# markers are a file's subject rather than its damage.
#
# Three callers need this answer and they must not disagree about it.
# rebase-status.sh reports markers at a stop, continue-rebase.sh refuses
# to advance past staged ones, and verify-rebase.sh sweeps the finished
# tree. A rule that lived in three copies would drift, and the drift
# that matters is the one where the reporting is stricter than the
# refusal, so a file gets flagged and then committed anyway.
#
# What counts as a marker: only the three directional lines. A bare
# ======= opens no conflict and closes none, and it is an ordinary
# Markdown setext heading underline, so matching it flags every document
# in a repository like this one.
#
# What does not count: a file whose subject is conflict markers. The
# resolve-rebase-conflicts skill documents the marker shape by showing
# it, and that document ships into every repository the package installs
# into, so the exemption is built in rather than left to each consumer
# to discover after the first false alarm. Anything else declares itself
# through a git attribute:
#
#   docs/merge-guide.md conflict-markers=documented
#
# Usage: marker-scan.sh [--staged] <path> [path ...]
#        --staged reads the index blob rather than the worktree file,
#        which is what a commit is about to carry.
# Exit:  0 nothing found, 1 markers found, 2 usage error.
set -euo pipefail

# --- environment hardening -------------------------------------------
# The agent reads this output, so the operator's preferences must not
# change its shape.
export LC_ALL=C
export PYTHONUTF8=1
unset CDPATH GREP_OPTIONS
IFS=$(printf ' \t\n')

readonly MARKER_RE='^(<<<<<<<|>>>>>>>|\|\|\|\|\|\|\|)( |$)'

staged=0
if [ "${1:-}" = "--staged" ]; then
  staged=1
  shift
fi

if [ "$#" -eq 0 ]; then
  printf 'usage: marker-scan.sh [--staged] <path> [path ...]\n' >&2
  exit 2
fi

# exempt reports whether markers in this path are its subject matter.
exempt() {
  case $1 in
  */skills/resolve-rebase-conflicts/SKILL.md | skills/resolve-rebase-conflicts/SKILL.md)
    return 0
    ;;
  esac
  [ "$(git check-attr conflict-markers -- "$1" 2>/dev/null | sed 's/.*: //')" = documented ]
}

found=0
for path in "$@"; do
  [ -n "$path" ] || continue
  exempt "$path" && continue

  if [ "$staged" = 1 ]; then
    git cat-file -e ":$path" 2>/dev/null || continue
    hits=$(git cat-file blob ":$path" 2>/dev/null | grep -cE "$MARKER_RE" || true)
  else
    [ -f "$path" ] || continue
    hits=$(grep -cE "$MARKER_RE" "$path" 2>/dev/null || true)
  fi

  if [ "${hits:-0}" -gt 0 ]; then
    printf '%s  %s marker line(s)\n' "$path" "$hits"
    found=1
  fi
done

exit "$found"
