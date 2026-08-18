#!/usr/bin/env bash
# new-retro — create a retrospective directory and copy in its evidence.
#
# Someone reads a retrospective once and acts on it, but its evidence has to
# remain available afterwards. Output goes under the MAIN checkout, never the
# worktree that ran the analysis, because worktrees get deleted. The transcript
# is copied rather than referenced for the same reason: a path under
# ~/.codex/sessions/ is not a stable location.
#
# Re-running is safe. The canned reports refresh, and an existing RETRO.md is
# left exactly as the author left it.
#
# Written to bash 3.2 so it runs on a stock macOS shell.
set -euo pipefail

# --- environment hardening -------------------------------------------
# This resolves paths from git and writes files an agent then reads, so
# the operator's preferences must not change what it does. LC_ALL pins
# collation, because sort order and the [a-z] ranges shift with the
# locale. The unsets cover variables that silently retarget a command:
# CDPATH makes a relative cd print somewhere else, GIT_DIR points git at
# another repository entirely.
export LC_ALL=C
export PYTHONUTF8=1
unset CDPATH GIT_DIR GIT_WORK_TREE GREP_OPTIONS
IFS=$' \t\n'

here=$(cd "$(dirname "$0")" && pwd)
skill_dir=$(dirname "$here")
template="$skill_dir/templates/RETRO.md"

usage() {
  cat <<'USAGE'
usage: new-retro.sh <transcript.jsonl> [extra-artifact ...]

Creates <main worktree>/.codex/retros/YYYYMMDD_<session id>/ holding
RETRO.md plus artifacts/ (the transcript, the canned session.py reports,
and any extra files named on the command line).
USAGE
}

if [ $# -lt 1 ]; then
  usage >&2
  exit 2
fi

transcript=$1
shift

[ -f "$transcript" ] || {
  echo "new-retro: no such transcript: $transcript" >&2
  exit 1
}
[ -f "$template" ] || {
  echo "new-retro: missing template: $template" >&2
  exit 1
}

# The shared .git directory answers the same from every worktree, so its
# parent is the main checkout no matter where this runs.
common_dir=$(git rev-parse --path-format=absolute --git-common-dir 2>/dev/null) || {
  echo "new-retro: not inside a git repository" >&2
  exit 1
}
root=$(dirname "$common_dir")

# session.py parses the JSON, so the date comes from the session's own last
# record rather than from whenever this script runs. Its uv script shebang
# selects the interpreter, so it runs directly.
session_id=""
session_date=""
records=""
size_mb=""
while IFS='=' read -r key value; do
  case $key in
  SESSION_ID) session_id=$value ;;
  SESSION_DATE) session_date=$value ;;
  RECORDS) records=$value ;;
  SIZE_MB) size_mb=$value ;;
  *) ;;
  esac
done <<EOF
$("$here/session.py" meta "$transcript")
EOF

if [ -z "$session_id" ] || [ -z "$session_date" ]; then
  echo "new-retro: could not read session metadata" >&2
  exit 1
fi

outdir="$root/.codex/retros/${session_date}_${session_id}"
artifacts="$outdir/artifacts"
mkdir -p "$artifacts"

cp "$transcript" "$artifacts/transcript.jsonl"

for report in index errors loops lint; do
  "$here/session.py" "$report" "$transcript" >"$artifacts/$report.txt"
done

copied=0
for extra in "$@"; do
  if [ -e "$extra" ]; then
    cp -R "$extra" "$artifacts/"
    copied=$((copied + 1))
  else
    echo "new-retro: skipping missing artifact: $extra" >&2
  fi
done

retro="$outdir/RETRO.md"
if [ -f "$retro" ]; then
  retro_state="left alone (already exists)"
else
  # bash 3.2 has no ${var/.../...} on file contents directly, so read the
  # template once and substitute in place. No sed, because this machine has
  # GNU sed where the surrounding scripts assume BSD.
  body=$(cat "$template")
  body=${body//\{\{SESSION_ID\}\}/$session_id}
  body=${body//\{\{RECORDS\}\}/$records}
  body=${body//\{\{SIZE_MB\}\}/$size_mb}
  body=${body//\{\{ANALYZED\}\}/$(date +%Y-%m-%d)}
  printf '%s\n' "$body" >"$retro"
  retro_state="scaffolded from template"
fi

# Retros are local working notes. Keep them out of history through the
# repository-local exclude file instead of editing the checked-out .gitignore.
ignore_entry=".codex/retros/"
exclude="$common_dir/info/exclude"
mkdir -p "$(dirname "$exclude")"
touch "$exclude"
if grep -qxF "$ignore_entry" "$exclude" 2>/dev/null ||
  grep -qxF "${ignore_entry%/}" "$exclude" 2>/dev/null; then
  ignore_state="already ignored"
else
  printf '\n# Session retrospectives. Local working notes, never committed.\n%s\n' \
    "$ignore_entry" >>"$exclude"
  ignore_state="added to .git/info/exclude"
fi

echo "retro dir:  $outdir"
echo "RETRO.md:   $retro_state"
echo "artifacts:  transcript.jsonl, 4 canned reports, $copied extra"
echo "gitignore:  $ignore_state"
