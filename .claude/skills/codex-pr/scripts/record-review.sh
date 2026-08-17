#!/usr/bin/env bash
# record-review — record the exact PR draft an independent Codex reviewer passed.
set -euo pipefail

export LC_ALL=C
unset CDPATH GREP_OPTIONS
IFS=$' \t\n'

root=${1:-$(git rev-parse --show-toplevel)}
cd "$root"
readonly DRAFT=PR_AGENTDESC.md
stamp="$(git rev-parse --absolute-git-dir)/codex-pr-agentdesc.reviewed"

if [ "${2:-}" = clear ]; then
  rm -f "$stamp"
  printf 'REVIEW: CLEARED\n'
  exit 0
fi

[ -s "$DRAFT" ] || {
  printf 'record-review: no draft at %s\n' "$DRAFT" >&2
  exit 1
}

if command -v sha256sum >/dev/null 2>&1; then
  digest=$(sha256sum "$DRAFT" | cut -d' ' -f1)
else
  digest=$(shasum -a 256 "$DRAFT" | cut -d' ' -f1)
fi
base=$(sed -n 's/^base:[[:space:]]*//p' "$DRAFT" | head -1)
[ -n "$base" ] || {
  printf 'record-review: the draft has no base branch\n' >&2
  exit 1
}
printf '%s %s %s\n' "$digest" "$(git rev-parse HEAD)" "$(git rev-parse "$base")" >"$stamp"

printf 'REVIEW: RECORDED\n'
