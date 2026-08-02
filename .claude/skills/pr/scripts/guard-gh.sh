#!/usr/bin/env bash
# guard-gh — PreToolUse gate on Bash, scoped to the pr skill.
#
# create-pr.sh holds the gates: the template checks, the review
# signature, and the property resolution that has to happen before a
# pull request exists. All of that is worth nothing if the next call
# simply runs gh directly, and instructions alone do not survive a long
# context. This hook is what makes the single entry point single.
#
# The rule is an allowlist rather than a list of refusals. Reading is
# open, and everything that changes a pull request goes through the
# script. A denylist would have to name every verb gh has today and
# every verb it grows later; naming the four read-only ones instead
# means a new mutating verb arrives already covered.
#
# Scope note. A skill's hooks outlive the turn that invoked it, so this
# guard is still live while watch-pr, fix-pr, and merge-pr run. It
# therefore governs `gh pr` alone and leaves `gh run` to the skills that
# wrap it, because a broader claim here would refuse their legitimate
# calls.
#
# Exit 2 blocks and hands stderr back as the reason. Exit 0 defers to
# the normal permission flow. Verified against Claude Code 2.1.220: a
# skill-frontmatter PreToolUse hook receives the Bash payload with the
# command at .tool_input.command, and exit 2 does block the call.
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
IFS=$(printf ' \t\n')

payload=$(cat)
command=$(jq -r '.tool_input.command // ""' <<<"$payload")

deny() {
  printf 'Blocked by the pr skill guard.\n\n%s\n' "$1" >&2
  exit 2
}

# Anchor on a command position so a mention inside a heredoc body or a
# quoted message reads as the prose it is. The newline has to be a real
# one, because POSIX ERE reads \n as the letter n.
readonly AT_START=$'(^|[;&|(]|&&|\\|\\||\n)[[:space:]]*'

[[ $command =~ ${AT_START}gh[[:space:]]+pr[[:space:]]+([a-z-]+) ]] || exit 0

# Index 2, not 1: AT_START opens a group of its own, so the verb is the
# second capture rather than the first.
verb=${BASH_REMATCH[2]}

# The allowlist: verbs that only read. Anything else changes the pull
# request and belongs to create-pr.sh.
case $verb in
list | view | diff | status | checks) exit 0 ;;
esac

deny "\`gh pr ${verb}\` changes the pull request, and this workflow keeps every
such change behind one entry point:

  bash .claude/skills/pr/scripts/create-pr.sh

That script validates the description against the template, checks that
review-pr-description cleared the exact bytes on disk, resolves the
labels and every issue reference before anything is published, and
updates the open pull request when one already exists.

Reading stays open: gh pr list, view, diff, status, and checks all run
without asking."
