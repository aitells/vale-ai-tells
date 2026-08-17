#!/usr/bin/env bash
# preflight — gather every fact the commit skill needs before it stages
# or drafts anything.
#
# The commit SKILL.md inlines this through the !`...` preprocessor, so it
# runs once before the agent reads the skill body. That ordering is the
# point: the agent starts from a settled picture of the worktree instead
# of spending its first several tool calls rediscovering it, and the
# rebase-base decision that opens the workflow is already computed.
#
# Output is plain text under `== section ==` headers, each self-contained
# so a partially-read report still answers something. Nothing here
# touches the worktree, the index, or the branch. The one write is the
# guard mark in the git directory, which arms the commit guard for this
# run. The one network call fetches the base branch;
# COMMIT_PREFLIGHT_FETCH=0 skips it.
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

# Diff budget. The full patch is worth inlining when it is small enough
# to read, and actively harmful when it is not: an oversized paste
# crowds out the rest of the skill. Past the cap the report prints the
# per-file stat and tells the agent which paths to diff by hand.
readonly DIFF_LINE_CAP=${COMMIT_PREFLIGHT_DIFF_LINES:-600}
readonly DO_FETCH=${COMMIT_PREFLIGHT_FETCH:-1}
readonly FETCH_TIMEOUT=${COMMIT_PREFLIGHT_FETCH_TIMEOUT:-10}

# Commit-message bounds, mirrored from the shared commitlint hook so the
# agent drafts against the numbers that will actually judge it. The hook
# reads the same environment overrides, so a repo that retunes one gets a
# report that matches.
readonly HEADER_MIN=${COMMITLINT_HEADER_MIN_LENGTH:-10}
readonly HEADER_MAX=${COMMITLINT_HEADER_MAX_LENGTH:-80}
readonly BODY_MAX=${COMMITLINT_BODY_MAX_LINE_LENGTH:-72}
readonly FOOTER_MAX=${COMMITLINT_FOOTER_MAX_LINE_LENGTH:-100}
readonly TYPES=${COMMITLINT_TYPES:-"feat fix docs style refactor perf test build ci chore revert"}

section() { printf '\n== %s ==\n' "$1"; }

# none prints a placeholder when a listing came back empty, so a section
# never reads as truncated output.
none() { printf '(none)\n'; }

# run_with_timeout bounds a command that touches the network. macOS ships
# no coreutils `timeout`, so this uses perl's alarm, which is present on
# every macOS and CI image this repo targets. Without perl the command
# runs unbounded rather than not at all.
run_with_timeout() {
  local secs=$1
  shift
  if command -v perl >/dev/null 2>&1; then
    perl -e 'alarm shift; exec @ARGV' "$secs" "$@"
  else
    "$@"
  fi
}

# ahead_behind prints "ahead N, behind M" for $1 relative to $2, or a
# marker when either ref is missing.
ahead_behind() {
  local left=$1 right=$2 counts
  if ! git rev-parse --verify --quiet "$left" >/dev/null ||
    ! git rev-parse --verify --quiet "$right" >/dev/null; then
    printf 'unknown (missing ref)\n'
    return
  fi
  counts=$(git rev-list --left-right --count "$right...$left")
  printf 'ahead %s, behind %s\n' "${counts##*[[:space:]]}" "${counts%%[[:space:]]*}"
}

# behind_count prints just the behind count of $1 relative to $2, for the
# arithmetic the base decision needs.
behind_count() {
  local counts
  counts=$(git rev-list --left-right --count "$2...$1" 2>/dev/null) || {
    printf '0\n'
    return
  }
  printf '%s\n' "${counts%%[[:space:]]*}"
}

root=$(git rev-parse --show-toplevel)
cd "$root"
branch=$(git rev-parse --abbrev-ref HEAD)

# Default branch, preferring what the remote actually points HEAD at
# over a guess. A worktree cloned without the symref falls back to a
# local main, then master.
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

# An interrupted rebase, merge, or cherry-pick makes every downstream
# step unsafe, so surface it before the agent stages anything.
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

# Arm the commit guard for this run. That guard is a skill-frontmatter
# hook, so it stays registered for the rest of the session and needs a
# signal telling it a workflow is actually open. HEAD is that signal:
# the workflow leaves HEAD alone until it commits, and the commit that
# ends the workflow moves HEAD past this mark and stands the guard down
# without anyone having to clear it.
guard_head=$(git rev-parse HEAD 2>/dev/null || printf 'unborn')
printf '%s' "$guard_head" >"$(git rev-parse --absolute-git-dir)/commit-workflow.head"
printf 'commit guard: armed at %s, inert again once HEAD moves\n' "$guard_head"

section "rebase base"
fetch_state=skipped
if [ "$DO_FETCH" = "1" ]; then
  if run_with_timeout "$FETCH_TIMEOUT" git fetch --quiet origin "$default_branch" 2>/dev/null; then
    fetch_state=ok
  else
    fetch_state="failed (origin counts below may be stale)"
  fi
fi
printf 'fetch:  %s\n' "$fetch_state"
printf 'default branch: %s\n' "$default_branch"
printf '%s vs origin/%s:  %s\n' "$default_branch" "$default_branch" \
  "$(ahead_behind "refs/heads/$default_branch" "refs/remotes/origin/$default_branch")"
printf '%s vs %s:  %s\n' "$branch" "$default_branch" \
  "$(ahead_behind HEAD "refs/heads/$default_branch")"
printf '%s vs origin/%s:  %s\n' "$branch" "$default_branch" \
  "$(ahead_behind HEAD "refs/remotes/origin/$default_branch")"

# Local main is only a safe rebase target when it carries everything
# origin has. One commit behind and rebasing onto it replays the branch
# over a stale base, which shows up later as a needless second rebase.
local_behind=$(behind_count "refs/heads/$default_branch" "refs/remotes/origin/$default_branch")
if [ "$local_behind" = "0" ]; then
  printf 'recommended base: %s\n' "$default_branch"
  printf 'reason: local %s carries everything origin/%s has\n' "$default_branch" "$default_branch"
else
  printf 'recommended base: origin/%s\n' "$default_branch"
  printf 'reason: local %s is %s commit(s) behind origin/%s\n' \
    "$default_branch" "$local_behind" "$default_branch"
fi

section "preconditions"
if git check-ignore --quiet COMMIT_AGENTMSG 2>/dev/null; then
  printf 'COMMIT_AGENTMSG gitignored: yes\n'
else
  printf 'COMMIT_AGENTMSG gitignored: NO — add it to .gitignore before drafting\n'
fi
if command -v mise >/dev/null 2>&1 && mise task info lint-commit-msg >/dev/null 2>&1; then
  printf 'mise run lint-commit-msg: present\n'
else
  printf 'mise run lint-commit-msg: ABSENT — stop and tell the operator\n'
fi

# prek installs shims into git's effective hooks directory, which
# core.hooksPath overrides when set.
hooks_dir=$(git config --get core.hooksPath || true)
[ -n "$hooks_dir" ] || hooks_dir="$(git rev-parse --git-common-dir)/hooks"
for hook in commit-msg pre-commit post-commit; do
  if [ -x "$hooks_dir/$hook" ]; then
    printf '%s hook: installed\n' "$hook"
  else
    printf '%s hook: not installed — run mise run repotools:prek-install\n' "$hook"
  fi
done
if [ -s COMMIT_AGENTMSG ]; then
  printf 'COMMIT_AGENTMSG: present, %s line(s) — a leftover draft; overwrite it\n' \
    "$(wc -l <COMMIT_AGENTMSG | tr -d ' ')"
else
  printf 'COMMIT_AGENTMSG: absent or empty (expected before drafting)\n'
fi

# The operator's standing answer to step 8, granted out of band through
# `mise run preapprove` and keyed on the Claude Code session. Absence is
# the default and the safe one: no record, no grant, and the
# confirmation stands as written. A missing session id reads the same
# way, so nothing here depends on the harness exporting one.
section "pre-approval"
preapproval=""
if [ -n "${CLAUDE_CODE_SESSION_ID:-}" ]; then
  preapproval="$(git rev-parse --absolute-git-dir)/preapprovals/$CLAUDE_CODE_SESSION_ID"
fi
if [ -n "$preapproval" ] && grant=$(grep '^commit ' "$preapproval" 2>/dev/null); then
  case ${grant##* } in
  touchid) how="a Touch ID prompt stands behind it" ;;
  *) how="no biometric prompt stood behind it" ;;
  esac
  printf 'commit: GRANTED, %s — step 8 skips the confirmation once every gate and the review pass\n' "$how"
else
  printf 'commit: not granted — step 8 confirms with the operator as written\n'
fi

section "staged changes"
staged=$(gitr diff --no-ext-diff --cached --name-status)
if [ -n "$staged" ]; then printf '%s\n' "$staged"; else none; fi

section "unstaged changes"
unstaged=$(gitr diff --no-ext-diff --name-status)
if [ -n "$unstaged" ]; then printf '%s\n' "$unstaged"; else none; fi

section "untracked files"
untracked=$(git ls-files --others --exclude-standard)
if [ -n "$untracked" ]; then printf '%s\n' "$untracked"; else none; fi

section "diffstat"
printf 'staged:\n'
gitr diff --no-ext-diff --cached --stat || true
printf '\nunstaged:\n'
gitr diff --no-ext-diff --stat || true

# The patch itself, tracked changes only. Untracked file bodies stay out:
# they are listed above, and a new vendored file would swamp the report.
section "diff"
patch=$(
  gitr diff --no-ext-diff --cached
  gitr diff --no-ext-diff
)
if [ -z "$patch" ]; then
  printf '(no tracked changes)\n'
elif [ "$(printf '%s\n' "$patch" | wc -l)" -le "$DIFF_LINE_CAP" ]; then
  printf '%s\n' "$patch"
else
  printf '(diff exceeds %s lines. Read it one path at a time with gitr diff --no-ext-diff\n' "$DIFF_LINE_CAP"
  printf 'and gitr diff --no-ext-diff --cached before grouping the commits.)\n'
fi

section "recent commits"
printf 'subjects:\n'
gitr log --oneline -10 2>/dev/null || printf '(no history)\n'
printf '\nlast two messages in full, for project style:\n'
gitr log -2 --pretty=format:'--- %h%n%B' 2>/dev/null || true

section "message rules"
printf 'types:   %s\n' "$TYPES"
printf 'subject: %s to %s chars, imperative mood, no trailing period\n' "$HEADER_MIN" "$HEADER_MAX"
printf 'body:    hard wrap at %s chars\n' "$BODY_MAX"
printf 'footer:  wrap at %s chars\n' "$FOOTER_MAX"
printf 'trailers: Assisted-by before Signed-off-by; Signed-off-by required\n'
signoff_name=$(git config --get user.name || echo UNSET)
signoff_email=$(git config --get user.email || echo UNSET)
printf 'Signed-off-by: %s <%s>\n' "$signoff_name" "$signoff_email"
