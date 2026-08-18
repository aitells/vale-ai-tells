#!/usr/bin/env bash
# watch-checks — emit one line per check as it settles, then exit.
#
# Written as an event stream for a long-running Codex exec session. Each
# stdout line reports a newly settled check without another gh query.
#
# The caller needs:
#
#   * one line per event, flushed as it happens
#   * every terminal state emits, not only the passing one, because a
#     watcher that prints nothing on failure is indistinguishable from a
#     watcher that is still waiting
#   * the command exits once nothing is pending, so the watch ends by
#     itself rather than sitting armed until the timeout
#
# It also works as a plain blocking call, where the exit code carries
# the outcome: 0 all passed, 1 something failed, 2 the wait ran out.
#
# Usage: watch-checks.sh [pull-request-number]
# Written to bash 3.2.
set -uo pipefail

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

readonly INTERVAL=${PR_CHECKS_INTERVAL:-30}
readonly TIMEOUT=${PR_CHECKS_TIMEOUT:-1800}
readonly APPEAR_TIMEOUT=${PR_CHECKS_APPEAR_TIMEOUT:-120}

root=$(git rev-parse --show-toplevel)
cd "$root" || exit 2

fail() {
  printf 'ERROR %s\n' "$1"
  exit 2
}

command -v gh >/dev/null 2>&1 || fail "gh is not installed"
command -v jq >/dev/null 2>&1 || fail "jq is not installed"
gh auth status >/dev/null 2>&1 || fail "gh is not authenticated"

number=${1:-}
if [ -z "$number" ]; then
  branch=$(git rev-parse --abbrev-ref HEAD)
  number=$(gh pr list --head "$branch" --state open --json number --jq '.[0].number' 2>/dev/null || true)
  [ -n "$number" ] || fail "no open pull request for ${branch}"
fi

printf 'WATCHING #%s\n' "$number"

# gh sorts checks into buckets: pass, fail, pending, skipping, cancel.
# Anything outside pending has finished moving.
snapshot() {
  raw_checks=$(gh pr checks "$number" --json name,bucket,link,workflow 2>/dev/null) ||
    fail "could not read checks for #${number}"
  printf '%s\n' "$raw_checks" | jq -e 'type == "array"' >/dev/null 2>&1 ||
    fail "gh returned an invalid checks response for #${number}"
  checks=$(printf '%s\n' "$raw_checks" | jq '
    map(. + {sort_id: (.link | capture("(?<id>[0-9]+)$").id | tonumber)})
    | sort_by(.workflow, .name, .sort_id)
    | group_by(.workflow, .name)
    | map(last | del(.sort_id))
  ') || fail "could not normalize checks for #${number}"
}

# A pull request opened seconds ago reports no checks at all. Waiting for
# the first one to register keeps an empty set from reading as success.
waited=0
while [ "$waited" -lt "$APPEAR_TIMEOUT" ]; do
  snapshot
  [ "$(printf '%s\n' "$checks" | jq 'length')" != "0" ] && break
  sleep 5
  waited=$((waited + 5))
done
snapshot
if [ "$(printf '%s\n' "$checks" | jq 'length')" = "0" ]; then
  printf 'NO CHECKS #%s registered after %ss\n' "$number" "$APPEAR_TIMEOUT"
  exit 2
fi

prev=""
seen=""
elapsed=0
failures=0

while :; do
  snapshot
  pending=$(printf '%s\n' "$checks" |
    jq '[.[] | select(.bucket == "pending")] | length')
  current=$(printf '%s\n' "$checks" |
    jq -r --argjson pending "$pending" \
      '.[] | select(.bucket != "pending" and (.bucket != "cancel" or $pending == 0)) | "\(.bucket)\t\(.workflow):\(.name)\t\(.name)\t\(.link)"' |
    sort)

  # Emit only what has settled since the previous look.
  #
  # A seen-set rather than comm. comm compares under the collation its
  # locale defines, so a name carrying spaces or punctuation could sort
  # one way and compare another, and the mismatch drops a FAIL line
  # instead of reporting it. Silence and success would then look alike,
  # which is the one thing this script exists to prevent.
  while IFS="$(printf '\t')" read -r bucket key name link; do
    [ -n "$name" ] || continue
    case "$seen" in
    *"|${key}|"*) continue ;;
    esac
    seen="${seen}|${key}|"
    case $bucket in
    pass) printf 'PASS  %s\n' "$name" ;;
    skipping) printf 'SKIP  %s\n' "$name" ;;
    fail | cancel)
      failures=$((failures + 1))
      printf 'FAIL  %s  %s\n' "$name" "$link"
      ;;
    *) printf '%s  %s\n' "$bucket" "$name" ;;
    esac
  done <<EOF
$current
EOF

  prev=$current

  if [ "$pending" = "0" ]; then
    break
  fi

  if [ "$elapsed" -ge "$TIMEOUT" ]; then
    printf 'TIMEOUT #%s after %ss with checks still running\n' "$number" "$TIMEOUT"
    exit 2
  fi
  sleep "$INTERVAL"
  elapsed=$((elapsed + INTERVAL))
done

# Recount from the final state rather than trusting the running tally,
# which a re-run of a failed job would have left stale.
failures=$(printf '%s\n' "$prev" | grep -c -E '^(fail|cancel)' || true)

if [ "$failures" = "0" ]; then
  printf 'ALL GREEN #%s\n' "$number"
  exit 0
fi

printf 'FAILED #%s with %s failing check(s). Hand it to the fix-pr skill.\n' "$number" "$failures"
exit 1
