#!/usr/bin/env bash
# squash-message — turn a published pull request description into a
# starting draft for the squash commit message.
#
# The description and the commit message answer to different readers. A
# description is Markdown, read once beside the diff, and carries
# sections about verification and review. A commit message is plain
# text, wrapped narrow, read years later by someone running git log, and
# carries only what still matters then. Squashing without a rewrite
# pastes the first into the second: headings, fences, and links land in
# the history, and the commit-msg gates reject the result.
#
# So this converts rather than copies. Summary, Why, and Risk become the
# body, because they answer why the change exists. Verification drops:
# it reports what a reviewer needed at the time, and it goes stale the
# moment the suite changes. Related becomes footer references, so the
# issue links survive as trailers.
#
# The output is a draft, not a finished message. Wrapping prose at a
# fixed width by machine leaves seams a person has to smooth, and the
# vale rules on the commit scope will have opinions. The skill's next
# step is to read this, rewrite it, and put it through the gates.
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

# gitr runs git for output this script parses, with every formatting
# knob pinned. log.showSignature is the one that matters most: it
# prepends a verification line per commit to stdout, ahead of the
# format string, so a --oneline listing silently becomes two lines per
# commit and any head -n cap shows half a branch as though it were all
# of it.
#
# Plain `git` stays available on purpose. Config reads, fetch, and push
# need the operator's real configuration: the sign-off identity may come
# from an includeIf work profile, and the network calls need credential
# helpers and any url.insteadOf rewriting.
gitr() {
  command git --no-pager \
    -c log.showSignature=false \
    -c color.ui=false -c color.diff=false -c color.status=false \
    -c core.quotePath=false \
    -c diff.noprefix=false -c diff.mnemonicPrefix=false \
    -c diff.renames=true -c diff.context=3 \
    "$@"
}

readonly DRAFT=SQUASH_AGENTMSG
readonly WRAP=${COMMITLINT_BODY_MAX_LINE_LENGTH:-72}

root=$(git rev-parse --show-toplevel)
cd "$root"

die() {
  printf 'squash-message: %s\n' "$1" >&2
  exit 1
}

command -v gh >/dev/null 2>&1 || die "gh is not installed"
gh auth status >/dev/null 2>&1 || die "gh is not authenticated"

number=${1:-}
if [ -z "$number" ]; then
  branch=$(git rev-parse --abbrev-ref HEAD)
  number=$(gh pr list --head "$branch" --state open --json number --jq '.[0].number' 2>/dev/null || true)
  [ -n "$number" ] || die "no open pull request for ${branch}. Pass a number explicitly."
fi

title=$(gh pr view "$number" --json title --jq '.title')
body=$(gh pr view "$number" --json body --jq '.body')
base=$(gh pr view "$number" --json baseRefName --jq '.baseRefName')
[ -n "$title" ] || die "pull request #${number} has no title"

# GitHub appends the number to the subject on a squash merge only when
# it writes the message itself. This workflow supplies the subject, so
# the reference is ours to add.
subject="${title} (#${number})"

# --- body ------------------------------------------------------------
#
# Sections are taken by name rather than by position, so a description
# that grew an extra heading still converts.
section_of() {
  printf '%s\n' "$body" | awk -v want="$1" '
    /^##[ \t]/ { inside = (tolower($0) ~ tolower("^## " want "[ \t]*$")); next }
    inside { print }
  '
}

# to_text strips the Markdown a commit message may not carry: fenced
# blocks, headings, emphasis, and link syntax. Backticked identifiers
# stay, because the commit scope allows them.
to_text() {
  awk '
    /^[ \t]*```/ { fenced = !fenced; next }
    fenced { next }
    /^#{1,6}[ \t]/ { next }
    { print }
  ' |
    sed -e 's/\[\([^]]*\)\](\([^)]*\))/\1 (\2)/g' \
      -e 's/\*\*\([^*]*\)\*\*/\1/g' \
      -e 's/__\([^_]*\)__/\1/g' \
      -e 's/^[ \t]*[-*][ \t]\{1,\}/- /'
}

# wrap reflows to $WRAP columns, keeping blank lines as paragraph breaks
# and leaving list items and indented lines alone.
wrap() {
  awk -v width="$WRAP" '
    function flush() {
      if (line != "") { print line; line = "" }
    }
    /^[ \t]*$/ { flush(); print ""; next }
    /^[-*] / || /^[ \t]+/ { flush(); print; next }
    {
      n = split($0, words, /[ \t]+/)
      for (i = 1; i <= n; i++) {
        if (words[i] == "") continue
        if (line == "") { line = words[i] }
        else if (length(line) + 1 + length(words[i]) <= width) { line = line " " words[i] }
        else { print line; line = words[i] }
      }
    }
    END { flush() }
  ' | awk 'BEGIN { blank = 1 } /^$/ { if (blank) next; blank = 1; print; next } { blank = 0; print }'
}

{
  printf '%s\n\n' "$subject"

  for want in summary why risk; do
    text=$(section_of "$want" | to_text | wrap |
      awk 'NF { seen = 1 } seen' | awk '{ lines[NR] = $0 } END { last = NR; while (last > 0 && lines[last] == "") last--; for (i = 1; i <= last; i++) print lines[i] }')
    if [ -n "$text" ]; then
      printf '%s\n\n' "$text"
    fi
  done
} >"$DRAFT"

# --- footer ----------------------------------------------------------
#
# Issue references in Related become closing keywords, so merging the
# squash closes what the branch set out to close.
related=$(section_of related | grep -o '#[0-9][0-9]*' | sort -u -t'#' -k2 -n || true)
if [ -n "$related" ]; then
  for ref in $related; do
    if [ "$ref" != "#${number}" ]; then
      printf 'Closes %s\n' "$ref" >>"$DRAFT"
    fi
  done
  printf '\n' >>"$DRAFT"
fi

# Trailers come from the commits themselves rather than the description,
# because that is where the sign-off actually happened. Order follows
# the shared trailer rule: attribution first, sign-off last.
trailers=$(gitr log --pretty=format:'%(trailers:only,unfold)' "origin/${base}..HEAD" 2>/dev/null || true)
for key in Assisted-by Signed-off-by; do
  printf '%s\n' "$trailers" | grep "^${key}:" | sort -u | while IFS= read -r line; do
    [ -n "$line" ] || continue
    printf '%s\n\n' "$line" >>"$DRAFT"
  done
done

# Collapse the trailing blank run to a single newline.
printf '%s\n' "$(cat "$DRAFT")" >"$DRAFT"

printf 'wrote %s for #%s\n\n' "$DRAFT" "$number"
cat "$DRAFT"
printf '\n---\nThis is a starting draft. Rewrite it so it reads as a commit message,\n'
printf 'then run the gates. Nothing merges until review-squash-message clears it.\n'
