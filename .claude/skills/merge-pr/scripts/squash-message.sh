#!/usr/bin/env bash
# squash-message — brief whoever writes the squash commit message, then
# leave them a skeleton to write into.
#
# A squash message is not a reformatted pull request description. It is
# the one commit a whole branch leaves behind, and it answers to someone
# running git log years from now who has neither the description nor the
# review thread beside them. Writing it means reading everything that
# landed and deciding what still matters. That is a writing exercise,
# not a transformation, and no script performs it. This one does not
# try.
#
# What a script can do is put every input in front of the writer at
# once: the description as published, every commit message the squash
# collapses, the diffstat, and the trailers those commits carry. Then it
# writes the parts that are mechanical rather than editorial — the
# subject, whose reference has to name this pull request, and the
# footer, whose closing keywords and trailers come from elsewhere — and
# leaves the body empty for the writer.
#
# Nothing caps the commit listing. A cap is what turns a briefing into a
# misleading sample: the reader cannot tell a branch of eight commits
# from the first eight of forty, and the whole question here is what one
# message owes to everything that actually landed.
#
# Every fact comes from gh rather than from the local repository. This
# skill also merges pull requests nobody here authored, a dependency
# bump being the usual case, and those branches are often not checked
# out at all.
#
# Usage: squash-message.sh [pull-request-number]
# Written to bash 3.2.
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

readonly DRAFT=SQUASH_AGENTMSG

root=$(git rev-parse --show-toplevel)
cd "$root"

die() {
  printf 'squash-message: %s\n' "$1" >&2
  exit 1
}

section() { printf '\n== %s ==\n' "$1"; }
none() { printf '(none)\n'; }

command -v gh >/dev/null 2>&1 || die "gh is not installed"
gh auth status >/dev/null 2>&1 || die "gh is not authenticated"

number=${1:-}
if [ -z "$number" ]; then
  branch=$(git rev-parse --abbrev-ref HEAD)
  number=$(gh pr list --head "$branch" --state open --json number --jq '.[0].number' 2>/dev/null || true)
  [ -n "$number" ] || die "no open pull request for ${branch}. Pass a number explicitly."
fi

# One request for the scalars. Tab-separated because a title may carry
# anything except a newline, and splitting on tabs alone keeps a title
# with spaces in it whole.
meta=$(gh pr view "$number" \
  --json title,baseRefName,headRefName,changedFiles,additions,deletions \
  --jq '[.title, .baseRefName, .headRefName, .changedFiles, .additions, .deletions] | @tsv') ||
  die "could not read pull request #${number}"
IFS=$(printf '\t') read -r title base head_ref changed added removed <<EOF
$meta
EOF
[ -n "$title" ] || die "pull request #${number} has no title"

body=$(gh pr view "$number" --json body --jq '.body' 2>/dev/null || true)

# Each record opens with a --- line, so the trailer pass below can tell
# one commit's message from the next.
commits=$(gh pr view "$number" --json commits \
  --jq '.commits[] | "--- " + .oid[0:7] + "  " + (.authors[0].name // "unknown")
        + "\n" + .messageHeadline
        + (if (.messageBody // "") == "" then "" else "\n\n" + .messageBody end)
        + "\n"' 2>/dev/null || true)
count=$(printf '%s\n' "$commits" | grep -c '^--- ' || true)

files=$(gh pr view "$number" --json files \
  --jq '.files[]? | [.additions, .deletions, .path] | @tsv' 2>/dev/null || true)

# --- trailers --------------------------------------------------------
#
# Taken from the commits rather than the description, because that is
# where the sign-off actually happened. This walks each record backwards
# from its final non-blank line, collecting trailer-shaped lines until
# it reaches one that is not.
#
# The walk crosses blank lines on purpose, which git's own trailer
# parser does not. Commits in these repositories routinely separate
# Assisted-by from Signed-off-by with one, and a walk that stopped there
# would drop the attribution on every squash. The cost is that a body
# whose last line happens to read `Word: something` can be swept in, and
# that lands visibly in the footer where the writer sees it.
#
# Stopping short of line 1 covers a commit with no body: its subject
# reads as `type: description`, which is trailer-shaped, and every
# one-line commit would otherwise contribute its own subject.
trailers=$(printf '%s\n' "$commits" | awk '
  function flush(   i, p, hits) {
    p = n
    hits = 0
    while (p > 1) {
      if (buf[p] ~ /^[ \t]*$/) { p--; continue }
      if (buf[p] !~ /^[A-Za-z][A-Za-z0-9-]*:[ \t]+[^ \t]/) break
      out[++hits] = buf[p]
      p--
    }
    for (i = hits; i >= 1; i--) print out[i]
    n = 0
  }
  /^--- / { flush(); next }
  { buf[++n] = $0 }
  END { flush() }
' | awk '!seen[$0]++')

# Order follows the shared trailer rule: attribution first, sign-off
# last. Anything else this repository's rule permits sits between them,
# where neither constraint reaches it.
ordered=$(printf '%s\n' "$trailers" | awk '
  NF == 0 { next }
  /^Assisted-by:/ { a[++na] = $0; next }
  /^Signed-off-by:/ { s[++ns] = $0; next }
  { o[++no] = $0 }
  END {
    for (i = 1; i <= na; i++) print a[i]
    for (i = 1; i <= no; i++) print o[i]
    for (i = 1; i <= ns; i++) print s[i]
  }
')

# --- closing references ----------------------------------------------
#
# Taken by section name rather than by position, so a description that
# grew an extra heading still yields its Related block.
section_of() {
  printf '%s\n' "$body" | awk -v want="$1" '
    /^##[ \t]/ { inside = (tolower($0) ~ tolower("^## " want "[ \t]*$")); next }
    inside { print }
  '
}

# The leading-character class keeps a cross-repository reference out of
# the footer. `tbhb/other#99` reduced to `#99` would close whichever
# unrelated issue holds that number here, and a closing keyword acts on
# merge without asking.
closes=$(section_of related |
  grep -oE '(^|[^[:alnum:]_/])#[0-9]+' | grep -oE '#[0-9]+' |
  sort -u -t'#' -k2 -n | awk -v self="#${number}" '$0 != self { print "Closes " $0 }' || true)

# --- the skeleton ----------------------------------------------------
#
# GitHub appends the number to the subject on a squash merge only when
# it writes the message itself. This workflow supplies the message, so
# the reference is ours to add, and squash-merge.sh reads it back to
# confirm the draft belongs to the pull request being merged.
subject="${title} (#${number})"

{
  printf '%s\n' "$subject"
  if [ -n "$closes" ]; then printf '\n%s\n' "$closes"; fi
  if [ -n "$ordered" ]; then printf '\n%s\n' "$ordered"; fi
} >"$DRAFT"

# --- the briefing ----------------------------------------------------

section "the pull request"
printf '#%s %s\n' "$number" "$title"
printf '%s into %s\n' "$head_ref" "$base"
printf '%s commits, %s files changed, %s insertions, %s deletions\n' \
  "$count" "$changed" "$added" "$removed"

section "description as published"
if [ -n "$body" ]; then printf '%s\n' "$body"; else none; fi

section "commits being collapsed, in full"
if [ -n "$commits" ]; then printf '%s\n' "$commits"; else none; fi

section "diffstat"
if [ -n "$files" ]; then
  printf '%s\n' "$files" | awk -F'\t' 'NF { printf "%7s+ %7s-  %s\n", $1, $2, $3 }'
  # The files list arrives paginated, so a wide branch can report fewer
  # rows than it changed. Say so rather than letting the listing read as
  # the whole diff.
  listed=$(printf '%s\n' "$files" | grep -c . || true)
  if [ "$listed" != "$changed" ]; then
    printf '\n%s of %s files listed; gh truncated the rest.\n' "$listed" "$changed"
  fi
else
  none
fi

section "trailers across the commits"
if [ -n "$ordered" ]; then printf '%s\n' "$ordered"; else none; fi

section "$DRAFT as written"
cat "$DRAFT"

cat <<'NOTE'

--- what is missing

The body. Everything above it is mechanical and everything in it is
not, so the skeleton stops where the writing starts.

Write the body between the subject and the footer. It accounts for the
whole stack of commits above in plain prose: the problem the branch
solves, the constraint that shaped the approach, what breaks without
it. Summary and Why from the description are the raw material. Discard
Verification, which reported what a reviewer needed at the time. Keep
Risk only where it names a rollback the reader would not guess.

Nothing merges until review-squash-message clears the result, and an
empty body fails that review by definition.
NOTE
