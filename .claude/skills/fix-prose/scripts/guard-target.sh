#!/usr/bin/env bash
# guard-target — PreToolUse gate on Write and Edit, refusing the caller's
# own edits to whichever file fix-prose was given.
#
# Forking the fixer keeps the lint findings and the retry rounds out of
# the caller's context. A caller that edits the target itself has to read
# those findings to do it, which wastes the entire saving, and the
# motivating case was four rounds of vale output against a twenty-line
# commit message. Instructions alone don't prevent it, because editing
# the file directly always takes fewer steps.
#
# The scoping comes from how the harness works rather than from
# anything this script inspects. Verified against Claude Code 2.1.220: a
# hook declared in a skill's frontmatter fires for the invoking session's
# tool calls and stays silent for an Agent-tool subagent's. So this
# refuses the caller and never sees the fixer, with neither of them
# having to identify itself.
#
# Unlike the pull request draft guard, this one names its own release.
# The fixer returns a finding rather than inventing text whenever
# clearing it would change what the document claims, which leaves those
# findings with the caller by design. A rule misfiring on correct prose
# reports the same way. Someone has to be able to overrule one, so the
# refusal below says how, and requiring a deliberate step is the point.
#
# Exit 2 blocks and returns stderr as the reason.
set -euo pipefail

# --- environment hardening -------------------------------------------
# LC_ALL pins collation for the git call below, and CDPATH is unset
# because it makes a relative path resolve somewhere else entirely.
export LC_ALL=C
unset CDPATH GREP_OPTIONS
IFS=$(printf ' \t\n')

payload=$(cat)

cwd=$(jq -r '.cwd // ""' <<<"$payload")
[ -d "$cwd" ] || exit 0

git_dir=$(command git -C "$cwd" rev-parse --absolute-git-dir 2>/dev/null) || exit 0
lock="$git_dir/fix-prose.lock"

# No lock means no run recorded a target, so nothing here is protected.
[ -s "$lock" ] || exit 0
locked=$(head -1 "$lock")

path=$(jq -r '.tool_input.file_path // ""' <<<"$payload")
[ -n "$path" ] || exit 0
case $path in
/*) ;;
*) path=$cwd/$path ;;
esac

[ "$path" = "$locked" ] || exit 0

printf 'Blocked by the fix-prose guard.\n\n%s\n' \
  "Clearing the prose findings on this file belongs to the fix-prose
skill, which runs the lint rounds in a subagent so their output stays
out of this session:

  Skill(fix-prose, args: \"${locked##*/} <lint command>  <what to address>\")

To hand it a decision, pass it in the arguments rather than applying it
here.

Where a finding needs a change of meaning, or a rule is misfiring on
correct prose, editing by hand is the right answer. Release the guard
first, and the edit is yours:

  rm ${lock}" >&2
exit 2
