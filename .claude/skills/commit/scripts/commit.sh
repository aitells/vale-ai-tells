#!/usr/bin/env bash
# commit — commit the drafted message, then check that what landed is
# what was staged.
#
# `git commit` alone does not settle that. The pre-commit hooks run
# through prek, which stashes and restores the worktree around them, and
# a run ending in failure can hand the index back short of what it was
# given. The retry then commits a subset of the group without saying so,
# and the only trace is a diffstat scrolling past. That is where the
# habit of chaining `git show --stat` after every commit came from: the
# agent was checking by hand for something a script can check once and
# report on.
#
# So the staged set is recorded first, and the commit is compared
# against it afterwards. A commit that dropped a path fails here with
# the path named rather than passing for a commit that looks fine.
#
# The review signature is checked here too. guard-git.sh sees the Bash
# tool call rather than the `git commit` inside this script, so moving
# the commit in here moves that gate in with it.
#
# Usage: commit.sh [git commit flags]
# Exit:  0 committed and verified
#        1 refused before committing, or committed short of the manifest
#        anything else is git's own status from a failed commit
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

# gitr runs git for output this script parses, with every formatting
# knob pinned. The commit itself does not go through it: that call is
# for the operator's hooks to run under their own configuration, and
# nothing here reads its output.
#
# --no-renames on both sides of the comparison matters more than it
# looks. Rename detection is a heuristic, and one side detecting a
# rename the other side missed turns into a path that appears dropped.
gitr() {
  command git --no-pager \
    -c log.showSignature=false \
    -c color.ui=false -c color.diff=false -c color.status=false \
    -c core.quotePath=false \
    "$@"
}

fail() {
  printf 'Refused by the commit workflow.\n\n%s\n' "$1" >&2
  exit 1
}

root=$(git rev-parse --show-toplevel)
cd "$root"
git_dir=$(git rev-parse --absolute-git-dir)

draft="$root/COMMIT_AGENTMSG"
stamp="$git_dir/commit-agentmsg.reviewed"

[ -s "$draft" ] || fail "COMMIT_AGENTMSG is empty or missing. Draft the message first."

# sha256 of $1, portable across the coreutils and BSD spellings.
digest() {
  if command -v sha256sum >/dev/null 2>&1; then
    sha256sum "$1" | cut -d' ' -f1
  else
    shasum -a 256 "$1" | cut -d' ' -f1
  fi
}

if [ ! -f "$stamp" ]; then
  fail "review-commit-message has not run against this draft.

That review is the only gate on the things linting cannot see: claims the
diff does not support, restating the diff instead of explaining it, and
whether the staged change is really one logical change. Invoke the
review-commit-message skill, resolve what it returns, then commit."
fi

if [ "$(cat "$stamp")" != "$(digest "$draft")" ]; then
  fail "COMMIT_AGENTMSG changed after review-commit-message signed off, so the
reviewed text and the text about to be committed are no longer the same.

Run review-commit-message again against the current draft, then commit."
fi

# Only --amend passes through. Everything else this workflow cares
# about is supplied here, and an allowlist is what keeps the guard hook
# meaningful: the hook reads the Bash tool call, which says `bash
# commit.sh` and nothing about the flags underneath, so a pass-through
# would carry --no-verify straight past the gate that refuses it.
amending=false
for arg in "$@"; do
  case $arg in
  --amend) amending=true ;;
  *)
    fail "commit.sh takes --amend and nothing else. It supplies the message file
and the cleanup mode itself, and the flags refused elsewhere in this
workflow are refused here for the same reasons.

Received: ${arg}"
    ;;
  esac
done

staged() { gitr diff --no-ext-diff --cached --name-only --no-renames | sort; }

manifest=$(staged)
if [ -z "$manifest" ] && [ "$amending" = false ]; then
  fail "Nothing is staged, so there is nothing to commit.

Stage the paths this commit is about, one at a time:

  git add -- path/one path/two"
fi

# The commit runs under the operator's own git configuration apart from
# the cleanup mode. Left at its default of strip, git would drop every
# body line opening with a number sign, and it would do so after
# review-commit-message hashed the file, so the bytes the reviewer
# cleared would stop matching the bytes git records.
status=0
command git -c commit.cleanup=whitespace commit -F "$draft" "$@" || status=$?

if [ "$status" != 0 ]; then
  dropped=""
  [ -z "$manifest" ] || dropped=$(comm -23 <(printf '%s\n' "$manifest") <(staged))
  if [ -n "$dropped" ]; then
    printf '\nThe commit failed and the index came back short. These paths were\n' >&2
    printf 'staged before the attempt and are not staged now:\n\n' >&2
    printf '%s\n' "$dropped" | sed 's/^/  /' >&2
    printf '\nStage them again before retrying, or the retry commits a subset of\n' >&2
    printf 'the group without saying so.\n' >&2
  fi
  exit "$status"
fi

# What the commit actually holds, against what the manifest named. An
# amend carries its original contents too, so the test is coverage
# rather than equality: every path the manifest named has to be in
# there, and an amend bringing extra paths along is expected.
missing=""
if [ -n "$manifest" ]; then
  landed=$(gitr diff-tree --no-ext-diff --no-commit-id --name-only --no-renames -r HEAD | sort)
  missing=$(comm -23 <(printf '%s\n' "$manifest") <(printf '%s\n' "$landed"))
fi

gitr show --no-ext-diff --stat --format='%h %s' HEAD

if [ -n "$missing" ]; then
  printf '\nThe commit is short of what was staged. These paths were in the\n' >&2
  printf 'index before the commit and are not in it:\n\n' >&2
  printf '%s\n' "$missing" | sed 's/^/  /' >&2
  printf '\nStage them and fold them into the commit that just landed:\n\n' >&2
  printf '  git add -- <the paths above>\n' >&2
  printf '  bash .claude/skills/commit/scripts/commit.sh --amend\n' >&2
  exit 1
fi
