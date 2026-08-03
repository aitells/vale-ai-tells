#!/usr/bin/env bash
# preflight — gather every fact the pr skill needs before it drafts a
# description or opens anything.
#
# The pr SKILL.md inlines this through the !`...` preprocessor, so it
# runs once before the agent reads the skill body. The report is meant
# to be the last word on the branch: the commits that would land, their
# messages in full, the files they touch, the repository's label set,
# whether a pull request already exists, and the exact frontmatter to
# copy. An agent that has read this should not need to run git log, gh
# pr list, or gh label list to draft.
#
# Output is plain text under `== section ==` headers, each self-contained
# so a partially-read report still answers something. Two network calls
# happen: a fetch of the base branch, which PR_PREFLIGHT_FETCH=0 skips,
# and the pull request lookup the stale-draft rule below depends on.
#
# The one thing this mutates is a stale PR_AGENTDESC.md. The draft is the
# working copy of the description while a pull request is open, so it
# survives create-pr and merge-pr removes it at the end. A draft with no
# open pull request behind it is therefore a leftover from a run that
# stopped early, and leaving it in place is worse than removing it: the
# next run would read someone else's abandoned text as its own starting
# point. Removed rather than emptied, so a stale read of it cannot
# survive either.
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

# Budgets. A branch carrying a hundred commits is worth summarizing
# rather than transcribing, and an oversized paste crowds out the rest
# of the skill.
readonly LOG_CAP=${PR_PREFLIGHT_LOG_COMMITS:-20}
readonly DIFF_LINE_CAP=${PR_PREFLIGHT_DIFF_LINES:-400}
readonly ISSUE_CAP=${PR_PREFLIGHT_ISSUES:-15}
readonly DO_FETCH=${PR_PREFLIGHT_FETCH:-1}
readonly FETCH_TIMEOUT=${PR_PREFLIGHT_FETCH_TIMEOUT:-10}
readonly DRAFT=PR_AGENTDESC.md

section() { printf '\n== %s ==\n' "$1"; }
none() { printf '(none)\n'; }

# run_with_timeout bounds a command that touches the network. macOS
# ships no coreutils `timeout`, so this uses perl's alarm, which is
# present on every macOS and CI image this repo targets.
run_with_timeout() {
  local secs=$1
  shift
  if command -v perl >/dev/null 2>&1; then
    perl -e 'alarm shift; exec @ARGV' "$secs" "$@"
  else
    "$@"
  fi
}

# ahead_behind prints "ahead N, behind M" for $1 relative to $2.
ahead_behind() {
  local counts
  if ! git rev-parse --verify --quiet "$1" >/dev/null ||
    ! git rev-parse --verify --quiet "$2" >/dev/null; then
    printf 'unknown (missing ref)\n'
    return
  fi
  counts=$(git rev-list --left-right --count "$2...$1")
  printf 'ahead %s, behind %s\n' "${counts##*[[:space:]]}" "${counts%%[[:space:]]*}"
}

root=$(git rev-parse --show-toplevel)
cd "$root"
branch=$(git rev-parse --abbrev-ref HEAD)

default_branch=main
if remote_head=$(git symbolic-ref --quiet refs/remotes/origin/HEAD 2>/dev/null); then
  default_branch=${remote_head##*/}
elif ! git rev-parse --verify --quiet refs/heads/main >/dev/null &&
  git rev-parse --verify --quiet refs/heads/master >/dev/null; then
  default_branch=master
fi

section "worktree"
printf 'root:     %s\n' "$root"
printf 'branch:   %s\n' "$branch"
case $root in
*/.claude/worktrees/*) printf 'layout:   agent worktree under .claude/worktrees\n' ;;
*) printf 'layout:   primary checkout\n' ;;
esac
upstream=$(git rev-parse --abbrev-ref --symbolic-full-name '@{upstream}' 2>/dev/null || echo none)
printf 'upstream: %s\n' "$upstream"

git_dir=$(git rev-parse --git-dir)
in_progress=none
if [ -d "$git_dir/rebase-merge" ] || [ -d "$git_dir/rebase-apply" ]; then
  in_progress="rebase (finish or abort it first)"
elif [ -f "$git_dir/MERGE_HEAD" ]; then
  in_progress="merge (finish or abort it first)"
elif [ -f "$git_dir/CHERRY_PICK_HEAD" ]; then
  in_progress="cherry-pick (finish or abort it first)"
fi
printf 'in progress: %s\n' "$in_progress"

if [ "$branch" = "$default_branch" ]; then
  printf 'WARNING: this is the default branch. A pull request needs a branch of its own.\n'
fi

section "base and divergence"
fetch_state=skipped
if [ "$DO_FETCH" = "1" ]; then
  if run_with_timeout "$FETCH_TIMEOUT" git fetch --quiet origin "$default_branch" 2>/dev/null; then
    fetch_state=ok
  else
    fetch_state="failed (counts below may be stale)"
  fi
fi
printf 'fetch:  %s\n' "$fetch_state"
printf 'default branch: %s\n' "$default_branch"
printf 'recommended base: %s\n' "$default_branch"

base_ref="refs/remotes/origin/$default_branch"
if ! git rev-parse --verify --quiet "$base_ref" >/dev/null; then
  base_ref="refs/heads/$default_branch"
fi
printf 'comparing against: %s\n' "$base_ref"
printf '%s vs base:  %s\n' "$branch" "$(ahead_behind HEAD "$base_ref")"
merge_base=$(git merge-base HEAD "$base_ref" 2>/dev/null || echo unknown)
printf 'merge base: %s\n' "$merge_base"

section "commits that would land"
landing=$(git rev-list --count "$base_ref..HEAD" 2>/dev/null || echo 0)
printf 'count: %s\n\n' "$landing"
if [ "$landing" = "0" ]; then
  printf 'Nothing to open a pull request for. Commit the work first.\n'
else
  gitr log --oneline "$base_ref..HEAD" | head -n "$LOG_CAP"
  printf '\nmessages in full:\n'
  gitr log --reverse --pretty=format:'--- %h%n%B' "$base_ref..HEAD" | head -n 200
fi

section "commit types on the branch"
if [ "$landing" != "0" ]; then
  gitr log --format='%s' "$base_ref..HEAD" |
    sed -n 's/^\([a-z][a-z]*\)[(!:].*/\1/p' | sort | uniq -c | sort -rn
  printf '\nThe pull request title takes one of these types. A squash merge\n'
  printf 'turns that title into the commit subject on the default branch.\n'
else
  none
fi

section "changed files"
if [ "$landing" != "0" ]; then
  gitr diff --no-ext-diff --name-status "$base_ref...HEAD"
  printf '\n'
  gitr diff --no-ext-diff --stat "$base_ref...HEAD"
else
  none
fi

section "diff"
if [ "$landing" != "0" ]; then
  patch=$(gitr diff --no-ext-diff "$base_ref...HEAD")
  if [ "$(printf '%s\n' "$patch" | wc -l)" -le "$DIFF_LINE_CAP" ]; then
    printf '%s\n' "$patch"
  else
    printf '(diff exceeds %s lines. Read it one path at a time with\n' "$DIFF_LINE_CAP"
    printf 'gitr diff --no-ext-diff %s...HEAD -- <path> before drafting.)\n' "$base_ref"
  fi
else
  none
fi

section "push state"
dirty=$(git status --porcelain)
if [ -n "$dirty" ]; then
  printf 'uncommitted changes: yes — these will NOT be in the pull request\n'
  printf '%s\n' "$dirty"
else
  printf 'uncommitted changes: none\n'
fi
if [ "$upstream" = none ]; then
  printf 'pushed: no upstream yet; creating the pull request pushes the branch\n'
else
  printf 'upstream:  %s\n' "$upstream"
  printf 'vs upstream: %s\n' "$(ahead_behind HEAD "$upstream")"
fi

section "existing pull request"
gh_state=ok
if ! command -v gh >/dev/null 2>&1; then
  gh_state="gh is not installed"
elif ! gh auth status >/dev/null 2>&1; then
  gh_state="gh is not authenticated — run gh auth login"
fi
open_number=""
if [ "$gh_state" != ok ]; then
  printf '%s\n' "$gh_state"
else
  existing=$(gh pr list --head "$branch" --state all \
    --json number,state,isDraft,url,title \
    --template '{{range .}}#{{.number}} {{.state}}{{if .isDraft}} (draft){{end}} {{.title}}
{{.url}}
{{end}}' 2>/dev/null || true)
  open_number=$(gh pr list --head "$branch" --state open --json number \
    --jq '.[0].number' 2>/dev/null || true)
  if [ -n "$existing" ]; then
    printf '%s\n' "$existing"
    if [ -n "$open_number" ]; then
      printf 'One is open. Re-running create-pr.sh updates it rather than opening\n'
      printf 'a second one.\n'
    fi
  else
    printf 'none for %s\n' "$branch"
  fi
fi

section "repository"
if [ "$gh_state" = ok ]; then
  gh repo view --json nameWithOwner,defaultBranchRef \
    --template 'repo: {{.nameWithOwner}}
default branch: {{.defaultBranchRef.name}}
' 2>/dev/null || printf '(gh repo view failed)\n'
  printf '\nlabels:\n'
  gh label list --limit 100 2>/dev/null || printf '(none)\n'
  printf '\nopen milestones:\n'
  milestones=$(gh api 'repos/{owner}/{repo}/milestones' --jq '.[].title' 2>/dev/null || true)
  if [ -n "$milestones" ]; then printf '%s\n' "$milestones"; else none; fi
  printf '\nopen issues (newest first, for the Related section):\n'
  issues=$(gh issue list --state open --limit "$ISSUE_CAP" \
    --json number,title --template '{{range .}}#{{.number}} {{.title}}
{{end}}' 2>/dev/null || true)
  if [ -n "$issues" ]; then printf '%s\n' "$issues"; else none; fi
else
  printf '%s\n' "$gh_state"
fi

section "template sections"
template=.github/pull_request_template.md
if [ -f "$template" ]; then
  printf 'from %s, in this order:\n' "$template"
  grep '^## ' "$template" || printf '(the template declares no level 2 headings)\n'
else
  printf 'NO TEMPLATE at %s — stop and tell the operator\n' "$template"
fi

section "preconditions"
if git check-ignore --quiet "$DRAFT" 2>/dev/null; then
  printf '%s gitignored: yes\n' "$DRAFT"
else
  printf '%s gitignored: NO — add it to .gitignore before drafting\n' "$DRAFT"
fi
if command -v mise >/dev/null 2>&1 && mise task info lint-pr-description >/dev/null 2>&1; then
  printf 'mise run lint-pr-description: present\n'
else
  printf 'mise run lint-pr-description: ABSENT — stop and tell the operator\n'
fi
for skill in pr review-pr-description; do
  if [ -f ".claude/skills/$skill/SKILL.md" ]; then
    printf '%s skill deployed: yes\n' "$skill"
  else
    printf '%s skill deployed: NO — run apm install\n' "$skill"
  fi
done
stamp="$(git rev-parse --absolute-git-dir)/pr-agentdesc.reviewed"
if [ ! -s "$DRAFT" ]; then
  printf '%s: absent or empty (expected before drafting)\n' "$DRAFT"
elif [ "$gh_state" != ok ]; then
  printf '%s: present, %s line(s). Cannot tell whether it is stale because\n' \
    "$DRAFT" "$(wc -l <"$DRAFT" | tr -d ' ')"
  printf 'the pull request lookup did not run. Read it before overwriting.\n'
elif [ -z "$open_number" ]; then
  rm -f "$DRAFT" "$stamp"
  printf '%s: REMOVED. It carried no open pull request, so it was a leftover\n' "$DRAFT"
  printf 'from a run that stopped early.\n'
else
  printf '%s: present, the working copy for #%s\n' "$DRAFT" "$open_number"
  # Whether the draft still matches what is published decides the next
  # step, and finding out otherwise costs the agent two more calls.
  fm_end=$(awk 'NR > 1 && $0 == "---" { print NR; exit }' "$DRAFT" || true)
  title_line=$(awk -v last="${fm_end:-0}" 'NR > last && /^# / { print NR; exit }' "$DRAFT" || true)
  if [ -n "$title_line" ]; then
    drafted=$(awk -v start="$title_line" 'NR > start' "$DRAFT" | awk 'NF { seen = 1 } seen')
    published=$(gh pr view "$open_number" --json body --jq '.body' 2>/dev/null || true)
    if [ "$(printf '%s' "$drafted")" = "$(printf '%s' "$published")" ]; then
      printf 'It matches the published description, so nothing needs republishing.\n'
    else
      printf 'It differs from the published description. Republish with create-pr.sh\n'
      printf 'once the review clears it again.\n'
    fi
  fi
fi

section "draft"
# Scaffolding here rather than in an instruction keeps the sections
# matching the template as it stands, and leaves write-pr-description a
# file to fill instead of a shape to reproduce from memory. It runs
# after the sweep above, which decides what should be on disk at all.
scaffold="$(dirname -- "$0")/scaffold-description.sh"
if [ -f "$scaffold" ]; then
  bash "$scaffold" "$default_branch"
else
  printf '(scaffold-description.sh missing; run apm install)\n'
fi
