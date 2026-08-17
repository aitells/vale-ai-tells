#!/usr/bin/env bash
# preflight — resolve the transcript, open the retro, and report what the
# session looks like, before the skill body reads anything.
#
# The Codex skill runs this explicitly before analysis. Locating the
# transcript, scaffolding the retro,
# preserving the artifacts, and profiling the session are all mechanical,
# and doing them here means the agent starts from the numbers rather than
# spending its first several tool calls producing them.
#
# The one thing this cannot do is search. A transcript path is cheap to
# verify and expensive to guess, so an unusable argument stops the run
# with instructions for finding it rather than searching every project
# directory, which would cost more context than the analysis.
#
# Nothing here mutates the transcript. Usage: preflight.sh [path-or-id]
set -euo pipefail

# --- environment hardening -------------------------------------------
# The agent reads this output, so the operator's preferences must not
# change its shape. LC_ALL pins collation, because sort order and the
# [a-z] ranges shift with the locale. The unsets cover variables that
# silently retarget a command: CDPATH makes a relative cd print
# somewhere else, GIT_DIR points git at another repository.
export LC_ALL=C
export PYTHONUTF8=1
unset CDPATH GIT_DIR GIT_WORK_TREE GREP_OPTIONS
IFS=$' \t\n'

here=$(cd "$(dirname "$0")" && pwd)
skill=$(dirname "$here")
readonly PROJECTS="$HOME/.codex/sessions"
readonly LOOP_ROWS=${ANALYZE_PREFLIGHT_LOOPS:-12}

section() { printf '\n== %s ==\n' "$1"; }

# Print how to find the transcript, then stop. Every exit here is 0: the
# preprocessor inlines this output either way, and a nonzero status would
# lose the instructions that tell the agent what to do next.
cannot_resolve() {
  section "transcript"
  printf 'UNRESOLVED — %s\n' "$1"
  section "what to do"
  cat <<GUIDE
Do not open rollout files to search them. Reading transcripts to find
one costs more context than the analysis that follows.

Dispatch a delegated agent to locate it, following the template in
$skill/references/LOCATE_SESSION.md. Give it the fingerprint the operator
described: a filename the session created, an identifier, or a rule name
out of its output.

Then run this preflight again with the path it returns:

  bash $here/preflight.sh <path>

Codex stores rollouts under date directories in ~/.codex/sessions. Do not
infer a rollout path from the repository or worktree path.
GUIDE
  exit 0
}

# session.py runs through a uv script shebang, so a missing uv fails deep
# inside the scaffolding with "env: uv: No such file or directory". Check
# it here instead, where the message can say what to do about it.
if ! command -v uv >/dev/null 2>&1; then
  section "uv"
  printf 'MISSING — session.py selects its interpreter through a uv script\n'
  printf 'shebang, so every report here needs uv on PATH.\n\n'
  printf 'Install it, then run this preflight again:\n\n'
  printf '  brew install uv\n'
  exit 0
fi

arg=${1:-}
[ -n "$arg" ] || cannot_resolve "no path given"

# Accept a path, or a bare session id resolved against the projects tree.
transcript=""
if [ -f "$arg" ]; then
  transcript=$arg
elif [ -d "$PROJECTS" ]; then
  # A bare id names the UUID suffix under exactly one dated rollout path.
  candidate=$(find "$PROJECTS" -type f -name "*${arg%.jsonl}.jsonl" 2>/dev/null | head -2)
  count=$(printf '%s' "$candidate" | grep -c . || true)
  if [ "$count" = 1 ]; then
    transcript=$candidate
  elif [ "$count" -gt 1 ]; then
    cannot_resolve "the id matches more than one transcript; pass a full path"
  fi
fi

[ -n "$transcript" ] || cannot_resolve "not a readable file: $arg"

transcript=$(cd "$(dirname "$transcript")" && printf '%s/%s' "$(pwd)" "$(basename "$transcript")")
head -c 1 "$transcript" >/dev/null 2>&1 || cannot_resolve "cannot read: $transcript"
case $(head -c 1 "$transcript") in
'{') ;;
*) cannot_resolve "not JSON lines: $transcript" ;;
esac

section "transcript"
printf '%s\n' "$transcript"

# Scaffold the retro and preserve the artifacts. Everything the reports
# below print is written to disk too, so a later reader can check the work.
section "retro"
bash "$here/new-retro.sh" "$transcript" || {
  printf 'scaffolding failed — tell the operator\n'
  exit 0
}

retro_root=$(dirname "$(git rev-parse --path-format=absolute --git-common-dir 2>/dev/null || echo .)")
meta=$("$here/session.py" meta "$transcript")
stamp=$(printf '%s\n' "$meta" | sed -n 's/^SESSION_DATE=//p')
name=$(printf '%s\n' "$meta" | sed -n 's/^SESSION_ID=//p')
artifacts="$retro_root/.codex/retros/${stamp}_${name}/artifacts"

# The profile, inlined. These are the same reports sitting in artifacts/,
# trimmed to what frames the problem: what the session was made of, what
# repeated, and how the findings arrived.
section "index"
sed -n '1,24p' "$artifacts/index.txt" 2>/dev/null || printf '(missing)\n'

section "loops"
printf 'Ranked by rounds. Each round beyond the first is a wasted trip.\n\n'
head -n "$LOOP_ROWS" "$artifacts/loops.txt" 2>/dev/null || printf '(missing)\n'

section "lint"
sed -n '1,14p' "$artifacts/lint.txt" 2>/dev/null || printf '(missing)\n'

section "artifacts"
printf '%s\n' "$artifacts"
find "$artifacts" -maxdepth 1 -type f -exec basename {} \; 2>/dev/null | sort | sed 's/^/  /'

section "next"
cat <<'NEXT'
The transcript is resolved, the retro is open, and the reports are on
disk. Start at step 1 of the skill body, reading only what these line
numbers point at.
NEXT
