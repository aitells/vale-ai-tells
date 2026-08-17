#!/usr/bin/env bash
# context — everything a prose fix needs, and nothing else.
#
# The delegated writer runs this explicitly, so it starts with the
# findings and document while the parent context stays clear.
#
# That split is why the work belongs to a delegated agent.
#
# Read-only throughout. The orchestrator's preflight owns the
# preconditions; this gathers material.
#
# Usage: context.sh <target> <workflow-state> [lint command...]
set -uo pipefail

# --- environment hardening -------------------------------------------
# The agent reads this output, so the operator's preferences must not
# change its shape. LC_ALL pins collation, and CDPATH is unset because
# it makes a relative path resolve somewhere else entirely.
export LC_ALL=C
export PYTHONUTF8=1
unset CDPATH GREP_OPTIONS
IFS=$' \t\n'

section() { printf '\n== %s ==\n' "$1"; }

root=$(git rev-parse --show-toplevel 2>/dev/null) || {
  printf 'Not a git repository. Report BLOCKED.\n'
  exit 0
}
cd "$root" || exit 1
root=$(pwd -P)

target=${1:-}
state=${2:-}
shift 2 2>/dev/null || true

# Everything after the target and state, up to a --, is the command. Review
# notes live in the workflow state rather than in the delegation arguments.
lint=""
for word in "$@"; do
  [ "$word" = "--" ] && break
  lint="${lint:+$lint }$word"
done

case $target in
"$root"/*) target=${target#"$root"/} ;;
esac

if [ -z "$state" ] || [ ! -s "$state/target" ]; then
  printf 'No fix-prose workflow state was supplied. Report BLOCKED and stop.\n'
  exit 0
fi
expected=$(head -1 "$state/target")
if [ "$target" != "$expected" ]; then
  printf 'Workflow state belongs to %s, not %s. Report BLOCKED and stop.\n' "$expected" "$target"
  exit 0
fi

section "target"
printf 'path: %s\n' "$target"
printf 'root: %s\n' "$root"
printf 'lint: %s\n' "${lint:-(none given)}"

if [ ! -f "$target" ]; then
  printf '\nNo such file. Report BLOCKED and stop.\n'
  exit 0
fi

notes="$state/notes"
if [ -s "$notes" ]; then
  section "what the caller asked you to address"
  cat "$notes"
fi

section "the document, with line numbers"
# The findings below name lines, so they resolve against this listing
# without a separate read.
awk '{printf "%5d  %s\n", NR, $0}' "$target"

section "findings"
if [ -z "$lint" ]; then
  printf 'No lint command given. Report BLOCKED and stop.\n'
else
  out=$(eval "$lint" 2>&1)
  if [ -n "$out" ]; then
    printf '%s\n' "$out"
  else
    printf '(nothing)\n'
  fi
fi

section "whether that silence means anything"
# A path no .vale.ini section names loads no styles, so vale reads the
# file, applies nothing, and exits 0. That is byte for byte what a clean
# document produces, and reading it as clean is how a fix run reports
# success having done nothing. Known-bad text under the target's own
# path settles which one happened.
readonly CONTROL='This is a very robust and comprehensive design that does not use contractions and it is significantly better.'
# A third case hides behind the same silence. vale exits 2 or above when
# it fails outright, printing nothing on stdout, and a bare finding count
# reads that as zero the same way it reads an unscoped path. The status
# tells the two apart, so read it before counting.
if command -v vale >/dev/null 2>&1; then
  probe=$(printf '%s\n' "$CONTROL" |
    vale --path="$target" --output=ai-tells-agent.tmpl 2>&1)
  rc=$?
  hits=$(printf '%s\n' "$probe" | grep -c '^[0-9]' || true)
  if [ "$rc" -gt 1 ]; then
    printf 'ERROR: vale exited %s and linted nothing, so neither the\n' "$rc"
    printf 'silence above nor this probe measured the document:\n'
    printf '%s\n' "$probe" | sed 's/^/  /'
    printf 'Report BLOCKED.\n'
  elif [ "${hits:-0}" -eq 0 ]; then
    printf 'UNSCOPED: no .vale.ini section matches %s, so vale loads no\n' "$target"
    printf 'styles here. A clean run proves nothing. Report BLOCKED.\n'
  else
    printf 'Covered: control text draws %s findings at this path, so the\n' "$hits"
    printf 'rules are live and silence above would be real.\n'
  fi
else
  printf '(vale not on PATH)\n'
fi

section "what a replacement pass would clear"
# Findings whose rule carries its own correction need no judgment. The
# count is here so the fixer knows what the task below is worth before
# running it.
if command -v vale >/dev/null 2>&1; then
  found=$(vale --output=ai-tells-agent.tmpl "$target" 2>&1)
  rc=$?
  if [ "$rc" -gt 1 ]; then
    printf 'Unknown: vale exited %s rather than linting, so the count below\n' "$rc"
    printf 'would be zero for the wrong reason:\n'
    printf '%s\n' "$found" | sed 's/^/  /'
  else
    auto=$(printf '%s\n' "$found" | grep -c 'replace_with=' || true)
    printf '%s of the vale findings carry a replacement.\n' "${auto:-0}"
    if [ "${auto:-0}" -gt 0 ]; then
      printf 'Clear them first with:\n  mise run fix-prose-replacements %s\n' "$target"
    fi
  fi
else
  printf '(vale not on PATH)\n'
fi
