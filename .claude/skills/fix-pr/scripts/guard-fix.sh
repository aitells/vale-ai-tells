#!/usr/bin/env bash
# guard-fix — PreToolUse gate on Bash, scoped to the fix-pr skill.
#
# diagnose.sh reads every failing run once and prints the log tail
# beside the local task that reproduces it. Going straight to gh
# repeats that work a call at a time and loses the mapping, which is
# the part that turns a log into something to run.
#
# The line drawn here: a sweep of the failing steps belongs to the
# script, while a named job stays open, because reading one job's full
# log is the legitimate next step after the tail proves too short.
#
# Watching belongs to the watch-pr skill, so the watching forms are
# refused here too.
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
  printf 'Blocked by the fix-pr skill guard.\n\n%s\n' "$1" >&2
  exit 2
}

readonly AT_START=$'(^|[;&|(]|&&|\\|\\||\n)[[:space:]]*'

if [[ $command =~ ${AT_START}gh[[:space:]]+run[[:space:]]+view ]] &&
  [[ $command =~ (--log-failed|--log([[:space:]]|$)) ]] &&
  ! [[ $command =~ --job ]]; then
  deny "Sweeping the failing steps is what the skill's own diagnosis does, in one
call, with the reproducing task named beside each failure:

  bash .claude/skills/fix-pr/scripts/diagnose.sh <number>

Run that first. Once you need more than the tail it printed, a single
job's full log stays available:

  gh run view <run-id> --job <job-id> --log"
fi

# Amending means replacing the branch rather than extending it, and a
# bare --force replaces it whatever arrived in the meantime. The lease
# makes the push refuse instead, which is the whole difference between
# rewriting a commit you wrote and discarding work that landed while you
# were busy.
if [[ $command =~ ${AT_START}git[[:space:]]+push ]] &&
  [[ $command =~ (--force([[:space:]]|$)|[[:space:]]-f([[:space:]]|$)) ]] &&
  ! [[ $command =~ --force-with-lease ]]; then
  deny "A bare force push overwrites whatever the remote has, including commits
this worktree never saw. Use the lease instead:

  git push --force-with-lease origin HEAD

It refuses when the remote moved since your last fetch, which is exactly
the case a bare --force would destroy."
fi

if [[ $command =~ ${AT_START}gh[[:space:]]+pr[[:space:]]+checks ]] &&
  [[ $command =~ (--watch|--fail-fast) ]]; then
  deny "Waiting on checks belongs to the watch-pr skill, which streams each result
as an event rather than blocking a turn. Invoke that skill instead."
fi

exit 0
