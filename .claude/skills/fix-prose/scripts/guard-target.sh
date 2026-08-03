#!/usr/bin/env bash
# guard-target — PreToolUse gate on Write and Edit, refusing the caller's
# own edits to whichever file fix-prose was given.
#
# Forking the fixer keeps the lint findings and the retry rounds out of
# the caller's context. A caller that edits the target itself has to read
# those findings to do it, which wastes the entire saving, and the
# motivating case was four rounds of vale output against a twenty-line
# commit message. Instructions alone don't prevent it, because editing
# the file directly always takes fewer steps.
#
# The scoping comes from how the harness works rather than from
# anything this script inspects. Verified against Claude Code 2.1.220: a
# hook declared in a skill's frontmatter fires for the invoking session's
# tool calls and stays silent for an Agent-tool subagent's. So this
# refuses the caller and never sees the fixer, with neither of them
# having to identify itself.
#
# Unlike the pull request draft guard, this one names its own release.
# The fixer returns a finding rather than inventing text whenever
# clearing it would change what the document claims, which leaves those
# findings with the caller by design. A rule misfiring on correct prose
# reports the same way. Someone has to be able to overrule one, so the
# refusal below says how.
#
# That release covers one edit rather than the session. Which edits it
# covers is the whole design: a release the caller pays for once gets
# paid once and then covers everything, so the price has to recur.
#
# Exit 2 blocks and returns stderr as the reason.
set -euo pipefail

# --- environment hardening -------------------------------------------
# LC_ALL pins collation for the git call below, and CDPATH is unset
# because it makes a relative path resolve somewhere else entirely.
export LC_ALL=C
unset CDPATH GREP_OPTIONS
IFS=$' \t\n'

payload=$(cat)

cwd=$(jq -r '.cwd // ""' <<<"$payload")
[ -d "$cwd" ] || exit 0

git_dir=$(command git -C "$cwd" rev-parse --absolute-git-dir 2>/dev/null) || exit 0
lock="$git_dir/fix-prose.lock"

# No lock means no run recorded a target, so nothing here is protected.
[ -s "$lock" ] || exit 0
locked=$(head -1 "$lock")

# A lock outlives the document it named. Every file this guard protects
# is removed at the end of the workflow that produced it: the post-commit
# hook deletes COMMIT_AGENTMSG once a commit lands, and merge-pr clears
# PR_AGENTDESC.md and SQUASH_AGENTMSG. The next workflow then writes a
# new document at the same path, and a lock matching on the path alone
# refuses that write. Three recorded blocks were exactly that, a fresh
# commit draft caught by the previous commit's lock, and each one was
# answered by deleting the lock outright within seconds.
#
# So an absent path stands the guard down: the run that armed it is over,
# whatever became of it. Releasing from here rather than from a step at
# the end of the workflow is what makes that hold, because an abandoned
# run skips a closing step by definition while this check runs on
# whichever edit arrives next. The commit guard's HEAD mark is scoped the
# same way and for the same reason.
if [ ! -e "$locked" ]; then
  rm -f "$lock"
  exit 0
fi

path=$(jq -r '.tool_input.file_path // ""' <<<"$payload")
[ -n "$path" ] || exit 0
case $path in
/*) ;;
*) path=$cwd/$path ;;
esac

[ "$path" = "$locked" ] || exit 0

# A one-shot release covers this edit and no more. The lock outlives it,
# so the edit after this one meets the refusal again and the choice gets
# made per edit rather than once per session.
#
# The older release was deleting the lock, and that is how it got spent:
# one deletion covered everything that followed, so a caller who needed
# one hand edit kept the rest of them too. Most refusals on record were
# answered that way within seconds, several by a deletion appended to an
# unrelated command.
#
# The token is read after the path comparison above, so an edit to some
# other file leaves it unspent for the file it was armed for. Consuming
# it here is safe against a first attempt that fails, because a call
# rejected by the harness validation never reaches PreToolUse at all,
# and safe against a batch, because PreToolUse fires once per call and
# in sequence rather than concurrently.
release="$git_dir/fix-prose.release"
if [ -e "$release" ]; then
  rm -f "$release"
  exit 0
fi

printf 'Blocked by the fix-prose guard.\n\n%s\n' \
  "Clearing the prose findings on this file belongs to the fix-prose
skill, which runs the lint rounds in a subagent so their output stays
out of this session:

  Skill(fix-prose, args: \"${locked##*/} <lint command>  <what to address>\")

To hand it a decision, pass it in the arguments rather than applying it
here.

Where a finding needs a change of meaning, or a rule is misfiring on
correct prose, editing by hand is the right answer. Release one edit,
and it is yours:

  bash .claude/skills/fix-prose/scripts/release-once.sh

The lock survives that edit, so a second one means running it again.
Reach for it where the finding needs a decision. Where it needs a
rewording, the invocation above costs the same and spends its context
rather than this one." >&2
exit 2
