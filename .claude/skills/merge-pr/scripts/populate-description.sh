#!/usr/bin/env bash
# populate-description — rebuild PR_AGENTDESC.md from a pull request
# that already exists.
#
# The pr skill writes the draft on its way out. Every other skill meets
# the pull request already open, with the description living on GitHub
# and nothing on disk. Revising it there means fetching it back first,
# and reassembling the frontmatter from the properties the pull request
# actually carries rather than guessing at them.
#
# This is the inverse of what create-pr.sh publishes: that splits the
# draft into a title, a body, and a set of gh flags, and this puts the
# three back together.
#
# Deliberately never runs from a preflight. A caller can be one step
# inside a `pr` workflow that already has a draft in flight, and
# clobbering it there would throw away work nobody asked to discard.
# The skill calls this when it knows the draft is missing or stale.
#
# Never overwrites without --force, for the same reason.
#
# Usage: populate-description.sh [--force] [pull-request-number]
set -euo pipefail

# --- environment hardening -------------------------------------------
# The agent reads this output, so the operator's preferences must not
# change its shape. GH_REPO in particular would silently pull the
# description from a different repository.
export LC_ALL=C
export GH_PAGER=cat
export GH_PROMPT_DISABLED=1
unset CDPATH GH_REPO GH_HOST GREP_OPTIONS
IFS=$' \t\n'

readonly DRAFT=PR_AGENTDESC.md

force=0
if [ "${1:-}" = "--force" ]; then
  force=1
  shift
fi

root=$(git rev-parse --show-toplevel)
cd "$root"

die() {
  printf 'populate-description: %s\n' "$1" >&2
  exit 1
}

command -v gh >/dev/null 2>&1 || die "gh is not installed"
gh auth status >/dev/null 2>&1 || die "gh is not authenticated"

if [ -s "$DRAFT" ] && [ "$force" = 0 ]; then
  printf '%s already exists; left alone.\n' "$DRAFT"
  printf 'Pass --force to replace it with what the pull request currently says.\n'
  exit 0
fi

branch=$(git rev-parse --abbrev-ref HEAD)
number=${1:-}
if [ -z "$number" ]; then
  number=$(gh pr list --head "$branch" --state open --json number --jq '.[0].number' 2>/dev/null || true)
  [ -n "$number" ] || die "no open pull request for ${branch}. Pass a number."
fi

# One call for everything, so the frontmatter and the body describe the
# same moment rather than two.
fields=$(gh pr view "$number" \
  --json title,body,baseRefName,isDraft,labels,assignees,milestone 2>/dev/null) ||
  die "cannot read pull request #${number}"

printf '%s' "$fields" | python3 -c '
import json, sys

pr = json.load(sys.stdin)

def flow(values):
    return "[" + ", ".join(values) + "]"

labels = flow([l["name"] for l in pr.get("labels") or []])
assignees = flow([a["login"] for a in pr.get("assignees") or []])
milestone = (pr.get("milestone") or {}).get("title") or ""
title = (pr.get("title") or "").strip()
body = (pr.get("body") or "").replace("\r\n", "\n").strip()

out = []
out.append("---")
out.append("base: " + pr.get("baseRefName", ""))
out.append("draft: " + ("true" if pr.get("isDraft") else "false"))
out.append("labels: " + labels)
# Requested reviewers do not survive a round trip: gh reports them as
# pending requests, and re-sending one that has already reviewed is an
# error. The skill re-adds any it wants.
out.append("reviewers: []")
out.append("assignees: " + assignees)
out.append("milestone:" + ((" " + milestone) if milestone else ""))
out.append("---")
out.append("")
out.append("# " + title)
out.append("")
out.append(body)
sys.stdout.write("\n".join(out).rstrip("\n") + "\n")
' >"$DRAFT" || die "could not rebuild the draft from #${number}"

printf 'wrote %s from pull request #%s\n' "$DRAFT" "$number"
printf 'The title lost its (#%s) suffix if it carried one, because the\n' "$number"
printf 'draft holds the title alone and create-pr.sh re-derives the rest.\n'
