#!/usr/bin/env bash
# stamp-review — PostToolUse hook on the Skill tool, scoped to the
# merge-pr skill. Records that review-squash-message cleared a message,
# and which bytes it cleared.
#
# The reviewer never writes this signature itself. It runs as a
# read-only agent, so it could not even if asked, and a reviewer that
# signed its own verdict would be attesting to its own diligence.
# Instead the harness hands this hook the reviewer's verdict, and the
# hook decides. Only a clean verdict signs; a finding erases any earlier
# signature, so a message that once passed cannot ride an old stamp into
# the default branch.
#
# squash-merge.sh compares the signature against the draft on disk
# before it merges, so a message edited after review reads as unreviewed
# rather than as reviewed.
#
# Verified against Claude Code 2.1.220: the Skill payload carries the
# invoked skill at .tool_input.skill, its arguments at .tool_input.args,
# and the forked agent's returned text at .tool_response.result. The
# published hooks reference calls the first field skill_name, which does
# not appear in the payload.
set -euo pipefail

# --- environment hardening -------------------------------------------
# The agent reads this output, so the operator's preferences must not
# change its shape. LC_ALL pins collation, because sort and the [a-z]
# ranges below mean different things under a UTF-8 locale. The unsets
# cover variables that silently retarget a command: GH_REPO sends gh at
# another repository, CDPATH makes a relative cd print somewhere else.
export LC_ALL=C
export GH_PAGER=cat
export GH_PROMPT_DISABLED=1
export PYTHONUTF8=1
unset CDPATH GH_REPO GH_HOST GREP_OPTIONS
IFS=$' \t\n'

payload=$(cat)
skill=$(jq -r '.tool_input.skill // ""' <<<"$payload")

case $skill in
review-squash-message | */review-squash-message | *:review-squash-message) ;;
*) exit 0 ;;
esac

repo=$(jq -r '.tool_input.args // ""' <<<"$payload")
[ -n "$repo" ] || repo=$(pwd)

git_dir=$(git -C "$repo" rev-parse --absolute-git-dir 2>/dev/null) || exit 0
stamp="$git_dir/squash-agentmsg.reviewed"
draft="$repo/SQUASH_AGENTMSG"

verdict=$(jq -r '.tool_response.result // ""' <<<"$payload")

if grep -q 'VERDICT:[[:space:]]*PASS' <<<"$verdict" &&
  ! grep -q 'CHANGES[[:space:]]*REQUIRED' <<<"$verdict" &&
  [ -s "$draft" ]; then
  if command -v sha256sum >/dev/null 2>&1; then
    digest=$(sha256sum "$draft" | cut -d' ' -f1)
  else
    digest=$(shasum -a 256 "$draft" | cut -d' ' -f1)
  fi
  printf '%s' "$digest" >"$stamp"
else
  rm -f "$stamp"
fi

exit 0
