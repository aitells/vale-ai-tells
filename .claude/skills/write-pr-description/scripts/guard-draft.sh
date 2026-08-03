#!/usr/bin/env bash
# guard-draft — PreToolUse gate on Write and Edit, scoped to whichever
# pull request skill invoked it. Keeps the description drafting inside
# the write-pr-description subagent.
#
# The point of forking the writer is that the branch diff lands in its
# context instead of the caller's. A caller that edits the draft itself
# has to read the diff to do it, which spends the saving and skips the
# validator run the writer owes before returning.
#
# Instructions alone lose that argument, because editing the file
# directly is always the shorter path in the moment.
#
# The scoping falls out of how the harness works rather than from
# anything this script inspects. Verified against Claude Code 2.1.220:
# a hook declared in a skill's frontmatter fires for the invoking
# session's tool calls and does NOT fire for a subagent's. So this
# refuses the caller and never sees the writer, without either of them
# having to identify itself.
#
# (A settings.json hook behaves differently: those DO fire for subagent
# calls, and the payload then carries agent_id, agent_type, and effort,
# which the main session's payload lacks. If this guard ever moves to
# settings.json it would need to read agent_type to tell them apart.)
#
# Exit 2 blocks and hands stderr back as the reason.
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
path=$(jq -r '.tool_input.file_path // ""' <<<"$payload")

case ${path##*/} in
PR_AGENTDESC.md) ;;
*) exit 0 ;;
esac

printf 'Blocked by the pull request skill guard.\n\n%s\n' \
  "Drafting the description belongs to the write-pr-description skill, which
runs forked so the branch diff stays out of this session:

  Skill(write-pr-description, args: \"<repo root>  <what to address>\")

It writes PR_AGENTDESC.md, clears the mechanical validator, and reports
what it changed. Pair it with review-pr-description and repeat until
that review returns PASS.

To hand it findings, pass them in the arguments rather than applying
them here." >&2
exit 2
