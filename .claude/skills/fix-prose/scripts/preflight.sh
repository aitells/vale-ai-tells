#!/usr/bin/env bash
# preflight — settle what this run can and can't do, before anything
# spawns an agent.
#
# It answers three questions the caller would otherwise pay a subagent
# to discover: does the target exist, does the lint command's rule set
# cover its path, and is there any work to do. Each of those has a
# BLOCKED outcome, and reaching one here costs a Bash call rather than
# an agent.
#
# It deliberately prints no finding text. The fix-prose body loads into
# the caller's context rather than a fork, because a forked skill can't
# register the guard hook, so anything printed here lands in the exact
# context the skill exists to keep clear. Counts and verdicts only.
#
# The scoping check is the important one. Vale matches a path against
# the sections in .vale.ini, the match is exact, and a path no section
# names loads no styles at all: vale reads the file, applies nothing,
# and exits 0. That is byte for byte what a clean document produces. So
# this pushes known-bad text through vale under the target's own path,
# using --path to associate that path with stdin, and reports what came
# back. Findings mean the path carries rules. Silence from text this bad
# means it carries none.
#
# Usage: preflight.sh <target> [lint command...]
set -uo pipefail

# --- environment hardening -------------------------------------------
# The agent reads this output, so the operator's preferences must not
# change its shape. LC_ALL pins collation, and CDPATH is unset because
# it makes a relative path resolve somewhere else entirely.
export LC_ALL=C
export PYTHONUTF8=1
unset CDPATH GREP_OPTIONS
IFS=$' \t\n'

root=$(git rev-parse --show-toplevel 2>/dev/null) || {
  printf 'verdict: BLOCKED (not a git repository)\n'
  exit 0
}
cd "$root" || exit 1
root=$(pwd -P)

target=${1:-}
shift 2>/dev/null || true
lint="$*"

printf '== fix-prose preflight ==\n'
printf 'root:     %s\n' "$root"

if [ -z "$target" ]; then
  printf 'target:   (none given)\n'
  printf 'verdict:  BLOCKED (no target in the arguments; ask which file)\n'
  exit 0
fi

case $target in
"$root"/*) rel=${target#"$root"/} ;;
*) rel=$target ;;
esac

if [ ! -f "$rel" ]; then
  printf 'target:   %s (missing)\n' "$rel"
  printf 'verdict:  BLOCKED (no such file)\n'
  exit 0
fi
printf 'target:   %s\n' "$rel"
printf 'lint:     %s\n' "${lint:-(none given)}"

# --- scoping ---------------------------------------------------------
# Every word spelled correctly on purpose: seeding this with typos would
# make it stronger and would also trip cspell on this file, and
# silencing that means the kind of ignore comment this skill refuses.
readonly CONTROL='This is a very robust and comprehensive design that does not use contractions and it is significantly better.'

# vale exits 0 having found nothing, 1 having found something, and 2 or
# above having failed. Reading the finding count alone conflates the last
# case with the first: a missing template or an unreadable config prints
# nothing on stdout, and counting that as zero findings reports the path
# as unscoped when nothing was measured at all. The status separates
# them, so keep vale last in the pipeline and read it before the count.
if command -v vale >/dev/null 2>&1; then
  probe=$(printf '%s\n' "$CONTROL" |
    vale --path="$rel" --output=ai-tells-agent.tmpl 2>&1)
  rc=$?
  hits=$(printf '%s\n' "$probe" | grep -c '^[0-9]' || true)
  if [ "$rc" -gt 1 ]; then
    printf 'scoping:  ERROR (vale exited %s; it did not lint anything)\n' "$rc"
    printf '%s\n' "$probe" | sed 's/^/          /'
    printf 'verdict:  BLOCKED (vale could not run, so this says nothing about the document)\n'
    exit 0
  fi
  if [ "${hits:-0}" -eq 0 ]; then
    printf 'scoping:  UNSCOPED (no .vale.ini section matches this path)\n'
    printf 'verdict:  BLOCKED (vale loads no styles here, so a clean run would prove nothing)\n'
    exit 0
  fi
  printf 'scoping:  covered (control text draws %s findings at this path)\n' "$hits"
else
  printf 'scoping:  unknown (vale not on PATH)\n'
fi

# --- is there work ---------------------------------------------------
# The output goes to /dev/null on purpose. Whether the gates pass is the
# caller's business; what they said is the fixer's.
if [ -n "$lint" ]; then
  if (eval "$lint") >/dev/null 2>&1; then
    printf 'gates:    CLEAN (the lint command reports nothing)\n'
    printf 'verdict:  BLOCKED (already clean; nothing to fix)\n'
    exit 0
  fi
  printf 'gates:    FAILING (there is work to do)\n'
fi

# --- leftovers -------------------------------------------------------
git_dir=$(git rev-parse --absolute-git-dir 2>/dev/null || true)
if [ -n "$git_dir" ] && [ -s "$git_dir/fix-prose.lock" ]; then
  printf 'guard:    a previous run left a lock on %s\n' "$(head -1 "$git_dir/fix-prose.lock")"
fi

printf 'verdict:  PROCEED\n'
