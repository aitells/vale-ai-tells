#!/usr/bin/env bash
# guard-rebase — PreToolUse gate on Bash, scoped to the rebase skill.
#
# The skill body already states these rules. This hook is what makes
# them hold: instructions degrade under a long context, an exit-2 deny
# does not. It stays scoped to the skill's frontmatter rather than to
# settings.json so it governs a rebase workflow and nothing else.
#
# Five rules, in order of how they fire:
#
#   1. A bare `git stash pop` or `git stash apply` is refused. Worktrees
#      share one global stash stack, and its indices shift whenever any
#      worktree pushes, so a bare pop takes whatever sits at stash@{0}
#      at that instant, which may belong to another session.
#   2. Starting a rebase by hand is refused unless it pins the two
#      settings itself. Both are operator preferences that can be on
#      without anyone here knowing, which is what the script exists to
#      settle. A caller spelling them out has settled it already, so
#      the rule reads the command rather than insisting on the script.
#   3. `git rebase --continue` is refused. git checks that no path is
#      unmerged and checks nothing else; a file staged with conflict
#      markers still in it continues happily into a commit.
#   4. `git rebase --skip` is refused. Skipping is right only where the
#      commit is already empty, and the script proves that before it
#      skips rather than taking anyone's word.
#   5. A bare `git push --force` is refused. A rebase rewrites the
#      branch, so a force push is the move that follows it, and the
#      lease is what keeps that from discarding someone else's work.
#
# `git rebase --abort` stays open. Abandoning is always safe, and the
# moment someone wants it is the wrong moment to make them read a
# refusal.
#
# Exit 2 blocks and hands stderr back as the reason. Exit 0 defers to
# the normal permission flow.
set -euo pipefail

# --- environment hardening -------------------------------------------
# The agent reads this output, so the operator's preferences must not
# change its shape. LC_ALL pins the [a-z] ranges the patterns below use.
export LC_ALL=C
export PYTHONUTF8=1
unset CDPATH GH_REPO GH_HOST GREP_OPTIONS
IFS=$(printf ' \t\n')

payload=$(cat)
command=$(jq -r '.tool_input.command // ""' <<<"$payload")

deny() {
  printf 'Blocked by the rebase skill guard.\n\n%s\n' "$1" >&2
  exit 2
}

# Heredoc bodies are data, not commands. A script written through a
# heredoc can discuss rebasing in its comments or its prose, and
# matching that text refuses a command that never touched the branch.
# Dropping those bodies before any rule reads the string keeps the rules
# pointed at what the shell will actually run.
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

# The subcommand has to sit where a command actually starts, so a
# mention of it inside an argument or a message reads as the prose it
# is. The newline has to be a real one: POSIX ERE reads \n as the letter
# n, so a spelled escape would miss a command on the second line.
readonly AT_START=$'(^|[;&|(]|&&|\\|\\||\n)[[:space:]]*'
readonly GIT_CMD='git([[:space:]]+-[cC][[:space:]]+[^[:space:]]+)*[[:space:]]+'

if ! [[ $command =~ ${AT_START}${GIT_CMD}(stash|rebase|push) ]]; then
  exit 0
fi

# Rule 1: a stash restore names its own entry.
if [[ $command =~ ${AT_START}${GIT_CMD}stash[[:space:]]+(pop|apply) ]]; then
  if ! [[ $command =~ stash[[:space:]]+(pop|apply)([[:space:]]+-[^[:space:]]+)*[[:space:]]+(stash@|[0-9a-f]{7,}) ]]; then
    deny "Worktrees share one global stash stack, and its indices shift whenever
any worktree pushes an entry. A bare pop takes whatever sits at stash@{0}
right then, which may be another session's work.

Inside a rebase, prefer --autostash, which start-rebase.sh already passes.
Where an entry genuinely has to come back, name it:

  git stash list --format='%gd %gs'
  git stash apply stash@{n}

Then drop that entry by the same name."
  fi
fi

# Rule 4 before rule 2, because --skip is a start-form-shaped string
# that the rebase pattern below would otherwise have to exclude.
if [[ $command =~ ${AT_START}${GIT_CMD}rebase[^\&\;\|]*[[:space:]]--skip([[:space:]]|$) ]]; then
  deny "--skip discards the commit git stopped on. That is right in exactly one
situation, where the base already carries the change so replaying it
produces nothing, and wrong in every other, where a commit's work
disappears with no record.

The script proves the commit is empty before it skips:

  bash .claude/skills/rebase/scripts/continue-rebase.sh --skip-empty

It refuses when the index carries anything against HEAD."
fi

if [[ $command =~ ${AT_START}${GIT_CMD}rebase[^\&\;\|]*[[:space:]]--continue([[:space:]]|$) ]]; then
  deny "git refuses to continue while a path is unmerged, and refuses nothing
else. A file staged with <<<<<<< still in it continues straight into a
commit, and the markers surface later as a puzzle.

  bash .claude/skills/rebase/scripts/continue-rebase.sh

That reads the staged blobs first, then continues."
fi

if [[ $command =~ ${AT_START}${GIT_CMD}rebase ]]; then
  # Everything that resumes or abandons an existing rebase, plus the
  # read-only forms, passes through. What is left is a start.
  if ! [[ $command =~ [[:space:]]--(abort|quit|edit-todo|show-current-patch|continue|skip)([[:space:]]|$) ]]; then
    # What this rule protects is the settings, not the script. A start
    # that spells both of them out has already done the thing the
    # script exists to guarantee, so two forms pass without it.
    #
    # The commit skill's last step is the first. That workflow ends in
    # a rebase of its own and writes both knobs out longhand. Refusing
    # it would put one skill in this package in the way of another's
    # documented command, which is the collision the shared guard
    # rules warn about: claim the forms your own scripts wrap, and no
    # more. What it gives up is the pre-rebase record, and
    # verify-rebase.sh already falls back to ORIG_HEAD without it.
    #
    # The gate sweep is the second, running a recipe at every commit.
    # That one is a verification rather than a move, so pinning
    # updateRefs is enough; a fixup! commit it collapsed would have to
    # exist in the range first, and nothing here creates one.
    if [[ $command =~ rebase\.updateRefs=false ]] &&
      { [[ $command =~ rebase\.autoSquash=false ]] ||
        [[ $command =~ [[:space:]]--exec([[:space:]]|=) ]]; }; then
      exit 0
    fi
    deny "Start the rebase through the script:

  bash .claude/skills/rebase/scripts/start-rebase.sh <base>

It pins rebase.updateRefs and rebase.autoSquash off, which are operator
preferences that can be on without this session knowing. updateRefs moves
other local branches pointing into the replayed range; autoSquash collapses
a fixup! commit that earned its own review. It also records the pre-rebase
tip, which is what verify-rebase.sh compares the result against.

Spelling both settings out passes too, which is the form the commit skill
uses at the end of its own run:

  git -c rebase.updateRefs=false -c rebase.autoSquash=false rebase --autostash <base>

So does the sweep that runs a gate at every commit:

  git -c rebase.updateRefs=false rebase --exec 'just lint' <base>"
  fi
fi

# Rule 5: a rebase rewrites the branch, so a force push is the natural
# next move and a bare --force is where the branch loses whatever
# arrived while this session worked.
if [[ $command =~ ${AT_START}${GIT_CMD}push ]]; then
  if [[ $command =~ [[:space:]](--force|-f)([[:space:]]|$) ]] &&
    ! [[ $command =~ --force-with-lease ]]; then
    deny "A bare --force overwrites the remote branch whatever it now holds. After
a rebase that is exactly the risk: the branch has been rewritten here, and
anything pushed to it elsewhere is what --force discards.

  git push --force-with-lease origin HEAD

The lease is the difference between replacing your own commits and
discarding someone else's."
  fi
fi

exit 0
