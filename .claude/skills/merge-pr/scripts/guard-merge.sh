#!/usr/bin/env bash
# guard-merge — PreToolUse gate on Bash, scoped to the merge-pr skill.
#
# squash-merge.sh holds the gates that keep a message nothing reviewed
# or linted off the default branch. A direct gh call skips all of them,
# and the result is permanent, because nothing lints a squash commit
# after the fact.
#
# The rule is an allowlist rather than a list of refusals. Reading is
# open, and everything that changes a pull request goes through the
# script. Naming the read-only verbs rather than the mutating ones means
# a verb gh grows later arrives already covered.
#
# Scope note. A skill's hooks outlive the turn that invoked it, so this
# guard is still live while pr, watch-pr, and fix-pr run. It governs
# `gh pr` alone, and its allowlist matches the pr skill's, so the two
# agree wherever both are active.
#
# Exit 2 blocks and hands stderr back as the reason. Verified against
# Claude Code 2.1.220: a skill-frontmatter PreToolUse hook receives the
# Bash payload with the command at .tool_input.command, and exit 2 does
# block the call.
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
  printf 'Blocked by the merge-pr skill guard.\n\n%s\n' "$1" >&2
  exit 2
}

# The newline has to be a real one: POSIX ERE reads \n as the letter n.
readonly AT_START=$'(^|[;&|(]|&&|\\|\\||\n)[[:space:]]*'

[[ $command =~ ${AT_START}gh[[:space:]]+pr[[:space:]]+([a-z-]+) ]] || exit 0

# Index 2, not 1: AT_START opens a group of its own, so the verb is the
# second capture rather than the first.
verb=${BASH_REMATCH[2]}

case $verb in
list | view | diff | status | checks) exit 0 ;;
esac

deny "\`gh pr ${verb}\` changes the pull request, and merging runs through one
entry point:

  bash .claude/skills/merge-pr/scripts/squash-merge.sh <number>

That script checks that the message names this pull request, that
review-squash-message cleared the exact bytes on disk, that the message
passes the commit-msg gates, and that the pull request is open, ready,
and green. It then merges, removes the drafts, and deletes the branch.

Calling gh directly writes a message onto the default branch that
nothing reviewed, and nothing lints a squash commit afterwards.

Reading stays open: gh pr list, view, diff, status, and checks all run
without asking."
