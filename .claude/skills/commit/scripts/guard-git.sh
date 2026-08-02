#!/usr/bin/env bash
# guard-git — PreToolUse gate on Bash, scoped to the commit skill.
#
# The skill body already states these rules. This hook is what makes them
# hold: instructions degrade under a long context, an exit-2 deny does
# not. It stays scoped to the skill's frontmatter rather than to
# settings.json so it governs a commit workflow and nothing else.
#
# Three rules, in order of how they fire:
#
#   1. Whole-tree staging (`git add -A`, `git add .`) is refused. An
#      atomic commit names its paths; a wildcard sweeps in whatever else
#      the worktree happens to be carrying.
#   2. `git commit -m`, `-am`, and `--no-verify` are refused. The message
#      comes from COMMIT_AGENTMSG so it passes the same gates twice, and
#      the hooks are the gate rather than an obstacle.
#   3. `git commit` is refused unless review-commit-message has signed
#      off on the exact bytes now in COMMIT_AGENTMSG. Editing the draft
#      after the review invalidates the signature, which is the point:
#      the reviewed text and the committed text are the same text.
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

  git commit -F COMMIT_AGENTMSG

The one sanctioned --no-verify is the throwaway work-in-progress commit
in the worktree rules, which is not part of a commit workflow."
fi

if [[ $invocation =~ (--message|[[:space:]]-[a-zA-Z]*m([[:space:]]|=|$)) ]]; then
  deny "An inline -m message skips COMMIT_AGENTMSG, so nothing lints it and
nothing reviews it. Write the message to COMMIT_AGENTMSG, then:

  git commit -F COMMIT_AGENTMSG"
fi

if [[ ! $invocation =~ (--file|[[:space:]]-F)([[:space:]]|=) ]]; then
  deny "This workflow commits the drafted file, so the editor never opens:

  git commit -F COMMIT_AGENTMSG"
fi

# Rule 3: the reviewed bytes and the committed bytes must match.
#
# Resolve the repository the command acts on rather than the one this
# hook happens to run in. A command can retarget git with `git -C` or a
# leading `cd`, and reading that target keeps the gate pointed at the
# repository about to receive the commit. Skipping this step fails open:
# a draft and signature sitting in the hook's own repository would clear
# a commit in some other one, which nothing reviewed.
target=""
if [[ $command =~ git[[:space:]]+-C[[:space:]]+([^[:space:]]+) ]]; then
  target=${BASH_REMATCH[1]}
elif [[ $command =~ ^[[:space:]]*cd[[:space:]]+([^[:space:]\;\&\|]+) ]]; then
  target=${BASH_REMATCH[1]}
fi

if [ -n "$target" ]; then
  root=$(git -C "$target" rev-parse --show-toplevel 2>/dev/null) ||
    deny "Cannot resolve a git repository at ${target}."
  git_dir=$(git -C "$target" rev-parse --absolute-git-dir 2>/dev/null)
else
  root=$(git rev-parse --show-toplevel)
  git_dir=$(git rev-parse --absolute-git-dir)
fi

draft="$root/COMMIT_AGENTMSG"
stamp="$git_dir/commit-agentmsg.reviewed"

[ -s "$draft" ] || deny "COMMIT_AGENTMSG is empty or missing. Draft the message first."

# sha256 of $1, portable across the coreutils and BSD spellings.
digest() {
  if command -v sha256sum >/dev/null 2>&1; then
    sha256sum "$1" | cut -d' ' -f1
  else
    shasum -a 256 "$1" | cut -d' ' -f1
  fi
}

current=$(digest "$draft")

if [ ! -f "$stamp" ]; then
  deny "review-commit-message has not run against this draft.

That review is the only gate on the things linting cannot see: claims the
diff does not support, restating the diff instead of explaining it, and
whether the staged change is really one logical change. Invoke the
review-commit-message skill, resolve what it returns, then commit."
fi

if [ "$(cat "$stamp")" != "$current" ]; then
  deny "COMMIT_AGENTMSG changed after review-commit-message signed off, so the
reviewed text and the text about to be committed are no longer the same.

Run review-commit-message again against the current draft, then commit."
fi

exit 0
