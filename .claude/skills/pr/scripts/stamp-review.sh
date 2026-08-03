#!/usr/bin/env bash
# stamp-review — PostToolUse hook on the Skill tool, scoped to the pr
# skill. Records that review-pr-description cleared a draft, and which
# bytes it cleared.
#
# The reviewer never writes this signature itself. It runs as a
# read-only agent, so it could not even if asked, and a reviewer that
# signed its own verdict would be attesting to its own diligence.
# Instead the harness hands this hook the reviewer's verdict, and the
# hook decides. Only a clean verdict signs; a finding erases any earlier
# signature, so a draft that once passed cannot ride an old stamp into a
# pull request.
#
# create-pr.sh compares the signature against the draft on disk before
# it publishes anything, so a draft edited after review reads as
# unreviewed rather than as reviewed.
#
# The signature lives in the per-worktree git directory of the
# repository the reviewer actually read, which the skill argument names.
# Parallel agent worktrees under .claude/worktrees therefore never read
# each other's signature.
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

# Match a bare name and a namespaced one, since a plugin or package
# install can prefix the skill it deploys.
case $skill in
review-pr-description | */review-pr-description | *:review-pr-description) ;;
*) exit 0 ;;
esac

# The skill takes the repository root as its argument. Without one it
# reviewed the directory this hook runs in.
repo=$(jq -r '.tool_input.args // ""' <<<"$payload")
[ -n "$repo" ] || repo=$(pwd)

git_dir=$(git -C "$repo" rev-parse --absolute-git-dir 2>/dev/null) || exit 0
stamp="$git_dir/pr-agentdesc.reviewed"
draft="$repo/PR_AGENTDESC.md"

verdict=$(jq -r '.tool_response.result // ""' <<<"$payload")

# A clean verdict says PASS and raises nothing. Anything else, including
# a reviewer that failed outright, leaves the pull request blocked.
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
