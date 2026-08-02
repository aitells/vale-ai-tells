#!/usr/bin/env bash
# lint-draft — run every prose gate over one drafted document, in a
# single call, and report all of it at once.
#
# The recipes this replaces each run one checker over many files.
# `just lint-prose x.md` runs vale and says nothing about spelling or
# structure, so a document that clears it can still fail cspell and
# rumdl afterwards. Answering them one at a time is how a twenty-line
# file turns into four rounds. Every gate reports here, whatever the
# ones before it found.
#
# The probe is the other half. Vale matches a path against the sections
# in .vale.ini, the match is exact, and a path no section binds styles to
# loads no styles at all. Vale then reads the file, applies nothing,
# prints nothing, and exits 0, which is byte for byte what a clean
# document produces. Measured in this repository: one paragraph of
# deliberately bad prose draws 9 findings as TODO.md and as
# docs/deep/nested.md, and zero as notes.txt, zero under styles/, zero
# under tmp/, and zero under .claude/skills/. The last three do match a
# section, but one that sets `BasedOnStyles =` on purpose, which reaches
# the reader the same way an unmatched path does.
#
# So this sends known-bad text through vale under the target's own path,
# using --path to associate that path with stdin, and never touching the
# file. Findings mean the path carries rules. Silence from text this bad
# means the path carries none, and the clean run above proved nothing.
#
# Findings print in the shape the ai-tells-agent template uses, and the
# exit code carries the result.
#
# Usage: lint-draft.sh <file>
set -uo pipefail

# --- environment hardening -------------------------------------------
# The agent reads this output, so the operator's preferences must not
# change its shape. LC_ALL pins collation, and CDPATH is unset because
# it makes a relative path resolve somewhere else entirely.
export LC_ALL=C
export PYTHONUTF8=1
unset CDPATH GREP_OPTIONS
IFS=$(printf ' \t\n')

root=$(git rev-parse --show-toplevel)
cd "$root" || exit 1

file=${1:-}
[ -n "$file" ] || {
  printf 'usage: lint-draft.sh <file>\n' >&2
  exit 2
}
[ -f "$file" ] || {
  printf '%s:1 [error] missing-file  no such file\n' "$file"
  exit 1
}

# Files with a recipe of their own. The probe below sends bare prose,
# which neither a shell script nor a rule file would take as prose, so
# without this they would both report as unscoped. The upstream copy of
# this script also names *.go and *.py; this repository has neither, and
# the *.yml arm is the one that earns its place here, because pointing
# this at a rule file is the realistic mistake.
case $file in
*.sh)
  printf '%s:1 [error] wrong-recipe  shell script; no prose recipe reads it\n' "$file"
  exit 2
  ;;
*.yml | *.yaml)
  printf '%s:1 [error] wrong-recipe  rule file; use just lint-messages\n' "$file"
  exit 2
  ;;
esac

rc=0

# --- the probe -------------------------------------------------------
# Bad on several axes at once, so any section with rules attached
# reports something. OverusedVocabulary, the weasel list, the
# AI-adjective pairs, and the commit-message claim rules all fire
# independently, which is why this draws 9 findings under every scoped
# Markdown path measured here and 4 under the commit-message paths.
#
# Every word is spelled correctly on purpose. Seeding it with typos
# would make the probe stronger and would also trip cspell on this
# file, and silencing that would mean adding an ignore comment.
readonly CONTROL='This is a very robust and comprehensive design that does not use contractions and it is significantly better.'

probe=$(printf '%s\n' "$CONTROL" |
  vale --path="$file" --output=ai-tells-agent.tmpl 2>/dev/null |
  grep -c '^[0-9]' || true)

if [ "${probe:-0}" -eq 0 ]; then
  printf '%s:1 [error] unscoped-path  no .vale.ini section binds styles to this path, so vale loads no styles and a silent run proves nothing; move the draft to a path the config names\n' "$file"
  rc=1
fi

# --- the gates -------------------------------------------------------
# Each runs whatever the ones before it reported. Collecting output and
# printing it together is the entire point of this script.
vale --output=ai-tells-agent.tmpl "$file" || rc=1

cspell --config .cspell.jsonc --no-summary --no-progress "$file" || rc=1

case $file in
*.md) rumdl check "$file" || rc=1 ;;
esac

exit "$rc"
