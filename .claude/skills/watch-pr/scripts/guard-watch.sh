#!/usr/bin/env bash
# guard-watch — PreToolUse gate on Bash, scoped to the watch-pr skill.
#
# The failure mode this skill exists to prevent is polling: a loop of
# `gh pr checks` calls, one turn each, every one reporting a state that
# has already moved on. watch-checks.sh replaces that with a single
# event stream, and the skill body says so. This hook is what makes the
# instruction hold once the context grows long.
#
# A plain `gh pr checks` for a one-off look stays allowed. Only the
# watching forms are refused, because those are the ones the script
# wraps.
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
command=$(jq -r '.tool_input.command // ""' <<<"$payload")

deny() {
  printf 'Blocked by the watch-pr skill guard.\n\n%s\n' "$1" >&2
  exit 2
}

# Anchor on a command position so a mention inside a heredoc body or a
# quoted string reads as the prose it is.
readonly AT_START=$'(^|[;&|(]|&&|\\|\\||\n)[[:space:]]*'

if [[ $command =~ ${AT_START}gh[[:space:]]+pr[[:space:]]+checks ]] &&
  [[ $command =~ (--watch|--fail-fast) ]]; then
  deny "This skill wraps the watch so each check becomes one event rather than
one turn:

  Monitor({
    command: \"bash .claude/skills/watch-pr/scripts/watch-checks.sh <number>\",
    description: \"checks on pull request <number>\",
    timeout_ms: 1800000,
    persistent: false,
  })

The script emits PASS, SKIP, and FAIL lines as they settle, then exits.
A single 'gh pr checks' without --watch is fine for a one-off look."
fi

if [[ $command =~ ${AT_START}gh[[:space:]]+run[[:space:]]+watch ]]; then
  deny "Watching a run directly reports a workflow rather than the pull request,
and it blocks a turn to do it. Use the skill's watcher instead:

  bash .claude/skills/watch-pr/scripts/watch-checks.sh <number>"
fi

exit 0
