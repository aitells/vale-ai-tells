#!/usr/bin/env bash
# stamp-review — record that an independent Codex reviewer cleared the
# current squash message, and which exact bytes it cleared.
#
# Codex has no PostToolUse hook for a delegated agent. The caller saves
# the delegated reviewer's exact final response and invokes this command
# explicitly. squash-merge.sh remains the terminal enforcement point.
set -euo pipefail

export LC_ALL=C
export GH_PAGER=cat
export GH_PROMPT_DISABLED=1
unset CDPATH GH_REPO GH_HOST GREP_OPTIONS
IFS=$' \t\n'

if [ "$#" -ne 2 ]; then
  printf 'usage: stamp-review.sh <repository> <verdict-file>\n' >&2
  exit 2
fi

repo=$1
verdict_file=$2
git_dir=$(git -C "$repo" rev-parse --absolute-git-dir)
draft="$repo/SQUASH_AGENTMSG"
stamp="$git_dir/squash-agentmsg.reviewed"
cd "$repo"

# Every attempt invalidates an earlier review first. A failed reviewer or
# malformed response must never leave an old clean stamp in place.
rm -f "$stamp"

[ -s "$draft" ] || {
  printf 'SQUASH_AGENTMSG is empty or missing.\n' >&2
  exit 1
}
[ -f "$verdict_file" ] || {
  printf 'review verdict file is missing: %s\n' "$verdict_file" >&2
  exit 1
}

# The review skill returns only its verdict block. Require exactly the
# clean verdict and the PR head it reviewed, so an ambiguous or partial
# response cannot look reviewed and a later push invalidates the pass.
verdict=$(tr -d '\r' <"$verdict_file" | sed '/^[[:space:]]*$/d')
pass=$(printf '%s\n' "$verdict" | sed -n '1p')
reviewed_head=$(printf '%s\n' "$verdict" | sed -n '2s/^PR HEAD: \([0-9a-f][0-9a-f]*\)$/\1/p')
lines=$(printf '%s\n' "$verdict" | wc -l | tr -d ' ')
if [ "$pass" != 'VERDICT: PASS' ] || [ "$lines" != 2 ] || [ ${#reviewed_head} -ne 40 ]; then
  printf 'The delegated review did not return an exact PASS verdict.\n' >&2
  exit 1
fi

command -v gh >/dev/null 2>&1 || {
  printf 'gh is not installed.\n' >&2
  exit 1
}
gh auth status >/dev/null 2>&1 || {
  printf 'gh is not authenticated.\n' >&2
  exit 1
}

number=$(head -1 "$draft" | sed -n 's/.*(#\([0-9][0-9]*\))[[:space:]]*$/\1/p')
[ -n "$number" ] || {
  printf 'SQUASH_AGENTMSG subject names no pull request.\n' >&2
  exit 1
}
current_head=$(gh pr view "$number" --json headRefOid --jq '.headRefOid' 2>/dev/null) || {
  printf 'could not read pull request #%s.\n' "$number" >&2
  exit 1
}
[ "$current_head" = "$reviewed_head" ] || {
  printf 'pull request #%s moved after review (%s is now %s).\n' \
    "$number" "$reviewed_head" "$current_head" >&2
  exit 1
}

if command -v sha256sum >/dev/null 2>&1; then
  draft_digest=$(sha256sum "$draft" | cut -d' ' -f1)
else
  draft_digest=$(shasum -a 256 "$draft" | cut -d' ' -f1)
fi
printf 'draft=%s\nhead=%s\n' "$draft_digest" "$reviewed_head" >"$stamp"

printf 'Stamped the current SQUASH_AGENTMSG review at PR head %s.\n' "$reviewed_head"
