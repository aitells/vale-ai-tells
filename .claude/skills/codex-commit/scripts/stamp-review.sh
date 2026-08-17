#!/usr/bin/env bash
# Record that the Codex parent received a clean independent review of the
# current commit draft and staged tree. commit.sh compares both immediately
# before committing, so any later draft or index edit invalidates the review.
set -euo pipefail

export LC_ALL=C
unset CDPATH GREP_OPTIONS
IFS=$' \t\n'

repo=${1:-}
verdict_file=${2:-}
[ -n "$repo" ] && [ -n "$verdict_file" ] || {
  printf 'usage: stamp-review.sh <repo> <verdict-file>\n' >&2
  exit 2
}

root=$(git -C "$repo" rev-parse --show-toplevel)
git_dir=$(git -C "$root" rev-parse --absolute-git-dir)
draft="$root/COMMIT_AGENTMSG"
stamp="$git_dir/commit-agentmsg.reviewed"
rm -f "$stamp"

[ -f "$verdict_file" ] || {
  printf 'stamp-review: review verdict file is missing: %s\n' "$verdict_file" >&2
  exit 1
}
verdict=$(tr -d '\r' <"$verdict_file" | sed '/^[[:space:]]*$/d')
[ "$verdict" = 'VERDICT: PASS' ] || {
  printf 'stamp-review: the delegated review did not return an exact PASS verdict\n' >&2
  exit 1
}
[ -s "$draft" ] || {
  printf 'stamp-review: COMMIT_AGENTMSG is empty or missing\n' >&2
  exit 1
}

if command -v sha256sum >/dev/null 2>&1; then
  message_digest=$(sha256sum "$draft" | cut -d' ' -f1)
else
  message_digest=$(shasum -a 256 "$draft" | cut -d' ' -f1)
fi
index_tree=$(git -C "$root" write-tree)
printf 'message %s\nindex %s\n' "$message_digest" "$index_tree" >"$stamp"
printf 'review stamp: recorded for current COMMIT_AGENTMSG and staged tree\n'
