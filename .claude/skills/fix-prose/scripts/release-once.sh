#!/usr/bin/env bash
# release-once — hand the caller one edit to the file fix-prose holds,
# then re-arm.
#
# The guard already had a release, which was deleting the lock. That
# form is why it stopped working: one deletion buys the rest of the
# session, so a caller who needed a single hand edit went on making
# every later edit by hand, and the rewording the fixer should have done
# arrived from the caller instead. The record bears that out. One
# session deleted the lock again and again over ninety minutes, some of
# those deletions stapled onto unrelated commands, and never once let it
# stand.
#
# This release covers one edit. The lock survives it, so the next edit
# meets the same refusal and the decision gets made per edit rather than
# once per session. That is the whole difference. A finding that
# genuinely needs a hand costs one command, and a finding that belongs
# to the fixer costs the same command again, which is the point at which
# handing it back is the cheaper move.
#
# guard-target.sh consumes the token. Probed against Claude Code
# 2.1.220: PreToolUse fires exactly once per tool call, and sequentially
# even for calls batched into a single message, so two edits issued
# together cannot both pass on one token. A call that fails the harness
# validation never reaches PreToolUse, so a malformed edit leaves the
# token unspent.
set -euo pipefail

# --- environment hardening -------------------------------------------
# LC_ALL pins collation for the git call below, and CDPATH is unset
# because it makes a relative path resolve somewhere else entirely.
export LC_ALL=C
unset CDPATH GREP_OPTIONS
IFS=$' \t\n'

git_dir=$(command git rev-parse --absolute-git-dir 2>/dev/null) || {
  printf 'Not inside a git repository, so no lock is held here.\n' >&2
  exit 1
}

lock="$git_dir/fix-prose.lock"
release="$git_dir/fix-prose.release"

if [ ! -s "$lock" ]; then
  printf 'No lock is held, so nothing needs releasing. The edit is yours.\n'
  exit 0
fi

locked=$(head -1 "$lock")

# A lock naming a file that no longer exists releases itself on the next
# edit, so a token here would go unread.
if [ ! -e "$locked" ]; then
  printf 'The locked path is gone, so the guard already stands aside:\n  %s\n' "$locked"
  exit 0
fi

: >"$release"

printf 'Released for one edit:\n  %s\n\n' "$locked"
printf '%s\n' "The next Write or Edit to that path goes through. The one after it
meets the guard again, so a second hand edit means running this again.

Where the finding is a rewording rather than a decision, hand it back
instead and let the fixer spend its own context on it:

  Skill(fix-prose, args: \"${locked##*/} <lint command>  <the finding>\")"
