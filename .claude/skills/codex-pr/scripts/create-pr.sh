#!/usr/bin/env bash
# create-pr — the one thing in this workflow that publishes a pull
# request description.
#
# The commit workflow could lean on git, whose own entry point carries
# hooks on both sides: one gates what goes in, the other cleans up
# afterwards. Publishing a pull request has no such entry point. Rather
# than guess at an it-worked signal from the outside, this workflow owns
# the inside, so every gate runs here and so does the call they gate.
#
# Running it a second time updates the open pull request rather than
# opening another. A description goes stale the moment remediation adds
# work, and the fix for that is the same path that published it, so the
# same gates apply to the rewrite.
#
# The draft outlives this script. PR_AGENTDESC.md stays the working copy
# of the description for as long as the pull request is open, and the
# merge-pr skill removes it once the branch lands.
#
# The order matters. Everything that can fail offline fails before the
# branch is pushed, everything that needs the API is resolved before the
# pull request changes, and the draft survives every failure so a retry
# starts from the text that was already written.
#
# Written to bash 3.2 so it runs on a stock macOS shell.
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

readonly DRAFT=PR_AGENTDESC.md

root=$(git rev-parse --show-toplevel)
cd "$root"
git_dir=$(git rev-parse --absolute-git-dir)
readonly STAMP="$git_dir/codex-pr-agentdesc.reviewed"

here=$(CDPATH='' cd -- "$(dirname -- "$0")" && pwd)

die() {
  printf 'create-pr: %s\n' "$1" >&2
  exit 1
}

step() { printf '\n--- %s\n' "$1"; }

[ -s "$DRAFT" ] || die "no draft at ${DRAFT}. Draft the description first."

# --- gate 1: the mechanical checks -----------------------------------

step "validating ${DRAFT}"
bash "$here/validate-description.sh" "$DRAFT" ||
  die "the description does not satisfy the template. Fix the findings above and retry."
printf 'clean\n'

# --- gate 2: the independent review ----------------------------------
#
# The independent reviewer records the digest explicitly after a PASS.
# Comparing that digest against the draft on disk makes an edit after
# review read as unreviewed.

step "checking the review signature"
digest() {
  if command -v sha256sum >/dev/null 2>&1; then
    sha256sum "$1" | cut -d' ' -f1
  else
    shasum -a 256 "$1" | cut -d' ' -f1
  fi
}

[ -f "$STAMP" ] ||
  die "review-pr-description has not cleared this draft. Invoke that skill, resolve
what it returns, then retry."

[ "$(awk '{ print $1 }' "$STAMP")" = "$(digest "$DRAFT")" ] ||
  die "${DRAFT} changed after codex-review-pr-description signed off. Review it again."
[ "$(awk '{ print $2 }' "$STAMP")" = "$(git rev-parse HEAD)" ] ||
  die "the branch changed after codex-review-pr-description signed off. Review it again."
reviewed_base=$(sed -n 's/^base:[[:space:]]*//p' "$DRAFT" | head -1)
[ -n "$reviewed_base" ] || die "the draft carries no base branch"
[ "$(awk '{ print $3 }' "$STAMP")" = "$(git rev-parse "$reviewed_base")" ] ||
  die "the base branch changed after codex-review-pr-description signed off. Review it again."
printf 'signed\n'

# --- parse the draft -------------------------------------------------

# The frontmatter shape is the one validate-description.sh enforces, so
# this parser can stay line-based rather than pulling in a YAML reader.
fm_end=$(awk 'NR > 1 && $0 == "---" { print NR; exit }' "$DRAFT")
[ -n "$fm_end" ] || die "the frontmatter never closes with ---"

field() {
  awk -v key="$1" -v last="$fm_end" '
    NR >= last { exit }
    index($0, key ":") == 1 {
      value = substr($0, length(key) + 2)
      sub(/^[ \t]+/, "", value)
      print value
      exit
    }
  ' "$DRAFT"
}

# sequence prints one entry per line from a YAML flow sequence.
sequence() {
  printf '%s' "$1" | sed 's/^\[//; s/\]$//' | tr ',' '\n' |
    sed 's/^[[:space:]]*//; s/[[:space:]]*$//; s/^"//; s/"$//; s/^'"'"'//; s/'"'"'$//' |
    grep -v '^$' || true
}

base=$(field base)
is_draft=$(field draft)
labels=$(sequence "$(field labels)")
reviewers=$(sequence "$(field reviewers)")
assignees=$(sequence "$(field assignees)")
milestone=$(field milestone)

title=$(awk 'NR > '"$fm_end"' && /^# / { print substr($0, 3); exit }' "$DRAFT")
[ -n "$title" ] || die "the draft carries no level 1 heading to use as the title"

# The body is everything after the title line. GitHub renders the title
# itself, and the frontmatter is this workflow's own bookkeeping, so
# neither belongs in what gets published.
title_line=$(awk 'NR > '"$fm_end"' && /^# / { print NR; exit }' "$DRAFT")
body_file="$git_dir/pr-agentdesc-body.md"
awk -v start="$title_line" 'NR > start' "$DRAFT" |
  awk 'NF { found = 1 } found' >"$body_file"

[ -s "$body_file" ] || die "the description has a title but no body"

# --- gate 3: resolve everything the API has to recognize -------------
#
# gh adds labels, reviewers, and the milestone after the pull request
# exists. An unknown one therefore fails *after* creation, leaving a
# published pull request missing the properties it was supposed to
# carry. Resolving them first turns that into a clean refusal.

step "resolving pull request properties"
command -v gh >/dev/null 2>&1 || die "gh is not installed"
gh auth status >/dev/null 2>&1 || die "gh is not authenticated. Run gh auth login."

known_labels=$(gh label list --limit 200 --json name --jq '.[].name' 2>/dev/null || true)
while IFS= read -r want; do
  [ -n "$want" ] || continue
  printf '%s\n' "$known_labels" | grep -qxF "$want" ||
    die "no label named \"${want}\" in this repository. Preflight printed the label set."
done <<EOF
$labels
EOF

if [ -n "$milestone" ]; then
  known_milestones=$(gh api 'repos/{owner}/{repo}/milestones' --jq '.[].title' 2>/dev/null || true)
  printf '%s\n' "$known_milestones" | grep -qxF "$milestone" ||
    die "no milestone named \"${milestone}\" in this repository."
fi

# Every issue or pull request the description points at has to exist. A
# reference to a number nobody opened is the cheapest kind of invented
# claim, and it is the one a machine can settle.
refs=$(grep -o '#[0-9][0-9]*' "$body_file" | sort -u | head -20 || true)
for ref in $refs; do
  number=${ref#\#}
  gh api "repos/{owner}/{repo}/issues/${number}" --jq '.number' >/dev/null 2>&1 ||
    die "the description references ${ref}, which is not an issue or pull request here."
done
printf 'labels, milestone, and references all resolve\n'

# --- push ------------------------------------------------------------

branch=$(git rev-parse --abbrev-ref HEAD)
open_number=$(gh pr list --head "$branch" --state open --json number --jq '.[0].number' 2>/dev/null || true)
step "pushing ${branch}"
if [ -n "$open_number" ]; then
  git push --force-with-lease origin "HEAD:${branch}"
elif git rev-parse --abbrev-ref --symbolic-full-name '@{upstream}' >/dev/null 2>&1; then
  git push origin "HEAD:${branch}"
else
  git push --set-upstream origin "HEAD:${branch}"
fi

# --- publish ---------------------------------------------------------

if [ -n "$open_number" ]; then
  step "updating pull request #${open_number}"
  state=$(gh pr view "$open_number" \
    --json baseRefName,isDraft,labels,reviewRequests,assignees,milestone)
  gh pr edit "$open_number" --base "$base" --title "$title" --body-file "$body_file"

  reconcile() {
    add_flag=$1
    remove_flag=$2
    desired=$3
    current=$4
    while IFS= read -r item; do
      [ -n "$item" ] || continue
      printf '%s\n' "$desired" | grep -qxF "$item" ||
        gh pr edit "$open_number" "$remove_flag" "$item" >/dev/null
    done <<EOF
$current
EOF
    while IFS= read -r item; do
      [ -n "$item" ] || continue
      printf '%s\n' "$current" | grep -qxF "$item" ||
        gh pr edit "$open_number" "$add_flag" "$item" >/dev/null
    done <<EOF
$desired
EOF
  }

  reconcile --add-label --remove-label "$labels" \
    "$(printf '%s' "$state" | jq -r '.labels[].name')"
  reconcile --add-reviewer --remove-reviewer "$reviewers" \
    "$(printf '%s' "$state" | jq -r '.reviewRequests[].login')"
  reconcile --add-assignee --remove-assignee "$assignees" \
    "$(printf '%s' "$state" | jq -r '.assignees[].login')"

  if [ -n "$milestone" ]; then
    gh pr edit "$open_number" --milestone "$milestone" >/dev/null
  elif [ "$(printf '%s' "$state" | jq -r '.milestone.title // empty')" ]; then
    gh pr edit "$open_number" --remove-milestone >/dev/null
  fi
  current_draft=$(printf '%s' "$state" | jq -r '.isDraft')
  if [ "$is_draft" = true ] && [ "$current_draft" = false ]; then
    gh pr ready "$open_number" --undo >/dev/null
  elif [ "$is_draft" = false ] && [ "$current_draft" = true ]; then
    gh pr ready "$open_number" >/dev/null
  fi
  gh pr view "$open_number" --json url --jq '.url'
  rm -f "$body_file"
  step "done"
  printf 'description updated. %s stays for the next edit.\n' "$DRAFT"
  exit 0
fi

step "opening the pull request"
set -- --base "$base" --title "$title" --body-file "$body_file"
if [ "$is_draft" = true ]; then
  set -- "$@" --draft
fi
while IFS= read -r item; do
  [ -n "$item" ] || continue
  set -- "$@" --label "$item"
done <<EOF
$labels
EOF
while IFS= read -r item; do
  [ -n "$item" ] || continue
  set -- "$@" --reviewer "$item"
done <<EOF
$reviewers
EOF
while IFS= read -r item; do
  [ -n "$item" ] || continue
  set -- "$@" --assignee "$item"
done <<EOF
$assignees
EOF
if [ -n "$milestone" ]; then
  set -- "$@" --milestone "$milestone"
fi

url=$(gh pr create "$@")
printf '%s\n' "$url"

rm -f "$body_file"

step "done"
printf 'pull request open. %s stays until merge-pr lands the branch.\n' "$DRAFT"
