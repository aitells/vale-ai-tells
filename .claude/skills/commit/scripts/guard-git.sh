#!/usr/bin/env bash
# guard-git — PreToolUse gate on Bash, scoped to the commit skill.
#
# The skill body already states these rules. This hook is what makes them
# hold: instructions degrade under a long context, an exit-2 deny does
# not. Declaring it in the skill's frontmatter rather than in
# settings.json keeps it out of a session that never asked for it, and
# the workflow scope below keeps it out of the rest of a session that
# did.
#
# Two rules, in order of how they fire:
#
#   1. Whole-tree staging (`git add -A`, `git add .`) is refused. An
#      atomic commit names its paths; a wildcard sweeps in whatever else
#      the worktree happens to be carrying.
#   2. A direct `git commit` is refused whatever flags it carries. The
#      workflow commits through scripts/commit.sh, and an inline -m or
#      a --no-verify is refused with its own reason before the general
#      one, because those two are wrong for reasons of their own.
#
# The review-signature check used to sit here and now sits in that
# script. A PreToolUse hook reads the Bash tool call, and the
# `git commit` inside a script is not one, so a gate placed here would
# go unread on the path the workflow actually takes. The script is also
# the only place that can compare the finished commit against what was
# staged for it, which a hook running before the commit cannot do.
#
# One entry point is what makes that split hold. Leaving a second,
# hook-gated way to commit would mean keeping both copies of the
# signature check in step with each other forever.
#
# Exit 2 blocks and hands stderr back as the reason. Exit 0 defers to the
# normal permission flow. Verified against Claude Code 2.1.220: a
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

# deny blocks the tool call, printing why plus the sanctioned
# alternative. The agent reads stderr, so the message is written for it.
deny() {
  printf 'Blocked by the commit skill guard.\n\n%s\n' "$1" >&2
  exit 2
}

# --- workflow scope ---------------------------------------------------
# A skill's frontmatter hooks outlive the turn that invoked the skill.
# Without a scope of its own this guard would go on policing every later
# `git add` and `git commit` in the session, and it did: a legitimate
# `git commit --amend` during unrelated release work was refused long
# after the commit workflow it belonged to had ended.
#
# preflight.sh arms the guard by recording the commit HEAD sat at when
# the workflow opened. A commit workflow leaves HEAD alone until it
# commits, so the mark matches for as long as the workflow is open, and
# the commit that ends the workflow moves HEAD past the mark and stands
# the guard down. Nothing has to remember to clear anything, which is
# the point: an end-of-workflow cleanup step is exactly the kind of
# thing an abandoned run skips.
#
# The mark is read from the repository holding the session rather than
# from wherever the command retargets, because the workflow is anchored
# where the skill ran. Outside a repository there is no workflow to
# scope, so the guard stands aside.
session_git_dir=$(git rev-parse --absolute-git-dir 2>/dev/null) || exit 0
armed_at=$(cat "$session_git_dir/commit-workflow.head" 2>/dev/null) || exit 0
head_now=$(git rev-parse HEAD 2>/dev/null) || head_now=unborn
[ "$armed_at" = "$head_now" ] || exit 0

# Heredoc bodies are data, not commands. A script written through a
# heredoc can discuss git in its comments or its prose, and matching
# that text refuses a command that never touched the index. Dropping
# those bodies before any rule reads the string keeps the rules pointed
# at what the shell will actually run.
#
# The terminator may be quoted (<<'EOF') and may be indented (<<-EOF),
# so both spellings are recognized and the closing line is matched after
# trimming its leading whitespace.
command=$(printf '%s' "$command" | awk '
  {
    if (term != "") {
      line = $0
      sub(/^[ \t]+/, "", line)
      if (line == term) { term = "" }
      next
    }
    rest = $0
    while (match(rest, /<<-?[ \t]*["'"'"']?[A-Za-z_][A-Za-z0-9_]*["'"'"']?/)) {
      word = substr(rest, RSTART, RLENGTH)
      rest = substr(rest, RSTART + RLENGTH)
      gsub(/^<<-?[ \t]*|["'"'"']/, "", word)
      term = word
    }
    print
  }
')

# Nothing to police unless git is being asked to stage or commit. The
# subcommand has to sit where a command actually starts, so a mention of
# it inside an argument or a message reads as the prose it is.
# The newline has to be a real one: POSIX ERE reads \n as the letter n,
# so a spelled escape would miss a command on the second line.
readonly AT_START=$'(^|[;&|(]|&&|\\|\\||\n)[[:space:]]*'
if ! [[ $command =~ ${AT_START}git[[:space:]]+(-C[[:space:]]+[^[:space:]]+[[:space:]]+)?(add|commit) ]]; then
  exit 0
fi

# Rule 1: no wildcard staging. Matches `-A`, `--all`, and a bare `.`
# argument, while leaving a real path such as `./cmd/foo` alone.
if [[ $command =~ ${AT_START}git[[:space:]]+add ]]; then
  if [[ $command =~ ${AT_START}git[[:space:]]+add([[:space:]]+-[^[:space:]]*)*[[:space:]]+(-A|--all)([[:space:]]|$) ]] ||
    [[ $command =~ ${AT_START}git[[:space:]]+add([[:space:]]+-[^[:space:]]*)*[[:space:]]+\.([[:space:]]|$) ]]; then
    deny "Whole-tree staging pulls in changes that do not belong to this commit.
Stage the paths this commit is about, one at a time:

  git add -- path/one path/two

Run git status first if you need to see what is outstanding."
  fi
fi

[[ $command =~ ${AT_START}git[[:space:]]+(-C[[:space:]]+[^[:space:]]+[[:space:]]+)?commit ]] || exit 0

# Narrow the flag checks to the commit invocation itself, stopping at the
# next shell separator. Reading flags off the whole command line mistakes
# an unrelated `grep -n` further down the pipeline for a `--no-verify` on
# the commit, and refuses a command that was never at fault.
if [[ $command =~ (git[[:space:]]+(-C[[:space:]]+[^[:space:]]+[[:space:]]+)?commit[^\&\;\|]*) ]]; then
  invocation=${BASH_REMATCH[1]}
else
  invocation=$command
fi

# Rule 2: the message comes from the drafted file, and the hooks run.
if [[ $invocation =~ (--no-verify|[[:space:]]-[a-zA-Z]*n([[:space:]]|$)) ]]; then
  deny "--no-verify skips the commit-msg gates this workflow exists to satisfy.
Commit the drafted message instead:

  bash .claude/skills/commit/scripts/commit.sh

The one sanctioned --no-verify is the throwaway work-in-progress commit
in the worktree rules, which is not part of a commit workflow."
fi

if [[ $invocation =~ (--message|[[:space:]]-[a-zA-Z]*m([[:space:]]|=|$)) ]]; then
  deny "An inline -m message skips COMMIT_AGENTMSG, so nothing lints it and
nothing reviews it. Write the message to COMMIT_AGENTMSG, then:

  bash .claude/skills/commit/scripts/commit.sh"
fi

# Every other spelling lands here, including the sanctioned flags. The
# script is the entry point, so a hand-written git commit is refused
# even when its flags are the right ones.
deny "This workflow commits through one script, which is where the gates a
hook on the tool call cannot reach live:

  bash .claude/skills/commit/scripts/commit.sh

That script checks that review-commit-message signed the exact bytes now
in COMMIT_AGENTMSG, records what is staged, commits, then reads the
commit back and names any staged path that did not land in it.

Add --amend to fold the staged change into the commit already there. No
other flag passes through."
