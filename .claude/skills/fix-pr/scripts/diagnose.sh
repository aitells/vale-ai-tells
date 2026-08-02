#!/usr/bin/env bash
# diagnose — read the failing checks on a pull request and say what to
# run locally to reproduce each one.
#
# A failing check answers "something broke" and nothing else. Turning
# that into work means finding the run, pulling the failing step's log,
# and knowing which local recipe covers the same ground. Done by hand
# that is three or four calls per failure, and the log is long enough
# that most of it is noise.
#
# So this does the three calls once and prints what remains: the failing
# step, the lines around the failure, and the recipe that reproduces it.
# The recipe mapping is a guess from the job name, and the report says
# so rather than pretending otherwise.
#
# Usage: diagnose.sh [pull-request-number]
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
IFS=$(printf ' \t\n')

readonly LOG_LINES=${FIX_PR_LOG_LINES:-80}

root=$(git rev-parse --show-toplevel)
cd "$root" || exit 2

die() {
  printf 'diagnose: %s\n' "$1" >&2
  exit 2
}

command -v gh >/dev/null 2>&1 || die "gh is not installed"
gh auth status >/dev/null 2>&1 || die "gh is not authenticated"

branch=$(git rev-parse --abbrev-ref HEAD)
number=${1:-}
if [ -z "$number" ]; then
  number=$(gh pr list --head "$branch" --state open --json number --jq '.[0].number' 2>/dev/null || true)
  [ -n "$number" ] || die "no open pull request for ${branch}. Pass a number explicitly."
fi

printf '== pull request ==\n'
gh pr view "$number" --json number,title,headRefName,headRefOid,url \
  --template '#{{.number}} {{.title}}
branch: {{.headRefName}} at {{.headRefOid}}
{{.url}}
' 2>/dev/null || die "cannot read #${number}"

# Fixing a failure means changing the code the failure came from. If the
# local branch has moved on, or is not the branch under test, the logs
# below describe something else.
printf '\n== local state ==\n'
head_oid=$(gh pr view "$number" --json headRefOid --jq '.headRefOid' 2>/dev/null || true)
head_ref=$(gh pr view "$number" --json headRefName --jq '.headRefName' 2>/dev/null || true)
local_oid=$(git rev-parse HEAD 2>/dev/null || true)
printf 'checked out: %s at %s\n' "$branch" "${local_oid:0:40}"
if [ "$branch" != "$head_ref" ]; then
  printf 'MISMATCH: the pull request is on %s, this worktree is on %s.\n' "$head_ref" "$branch"
  printf 'Check out that branch before fixing anything.\n'
elif [ "$local_oid" != "$head_oid" ]; then
  printf 'MISMATCH: local HEAD differs from the commit CI tested.\n'
  printf 'The logs below may describe code this worktree no longer has.\n'
else
  printf 'in sync with the commit CI tested\n'
fi
dirty=$(git status --porcelain 2>/dev/null || true)
if [ -n "$dirty" ]; then
  printf '\nuncommitted changes present:\n%s\n' "$dirty"
fi

failed=$(gh pr checks "$number" --json name,state,link \
  --jq '.[] | select(.state == "FAILURE" or .state == "TIMED_OUT" or .state == "CANCELLED" or .state == "ACTION_REQUIRED") | [.name, .link] | @tsv' \
  2>/dev/null || true)

if [ -z "$failed" ]; then
  printf '\n== checks ==\nNothing is failing on #%s.\n' "$number"
  gh pr checks "$number" 2>/dev/null || true
  exit 0
fi

# reproducer maps a job name onto the local recipe covering the same
# ground. The names come from this repository's own workflows, and an
# unrecognized job says so rather than guessing.
reproducer() {
  case $(printf '%s' "$1" | tr '[:upper:]' '[:lower:]') in
  *prose* | *vale*) printf 'just lint-prose\n' ;;
  *spell*) printf 'just lint-spelling\n' ;;
  *markdown* | *rumdl*) printf 'just lint-markdown\n' ;;
  *shell*) printf 'just lint-shell && just lint-shell-fmt\n' ;;
  *yaml*) printf 'just lint-yaml\n' ;;
  *toml*) printf 'just lint-toml\n' ;;
  *workflow* | *actionlint*) printf 'just lint-workflows\n' ;;
  *editorconfig*) printf 'just lint-editorconfig\n' ;;
  *arch*) printf 'just lint-go-arch\n' ;;
  *deadcode*) printf 'just lint-go-deadcode\n' ;;
  *lint*) printf 'just lint\n' ;;
  *race*) printf 'just test-race\n' ;;
  *cover*) printf 'just cover-check\n' ;;
  *test*) printf 'just test\n' ;;
  *vendor*) printf 'just vendor-check\n' ;;
  *vuln*) printf 'just vuln\n' ;;
  *gitleaks* | *secret*) printf 'just gitleaks\n' ;;
  *apm* | *validate*) printf 'apm install --frozen && apm audit --ci\n' ;;
  *fuzz*) printf 'just fuzz\n' ;;
  *) printf '(no local recipe maps to this job; read the log)\n' ;;
  esac
}

printf '\n== failures ==\n'
seen=""
while IFS="$(printf '\t')" read -r name link; do
  [ -n "$name" ] || continue
  printf '\n--------------------------------------------------------------\n'
  printf 'job:        %s\n' "$name"
  printf 'reproduce:  %s\n' "$(reproducer "$name")"
  printf 'run:        %s\n' "$link"

  run_id=$(printf '%s' "$link" | sed -n 's#.*/runs/\([0-9][0-9]*\).*#\1#p')
  if [ -z "$run_id" ]; then
    printf 'log:        (not a workflow run; open the link)\n'
    continue
  fi

  # A workflow with several failing jobs points them all at one run, and
  # its failing-step log covers every one of them. Read it once.
  case " $seen " in
  *" $run_id "*)
    printf 'log:        already printed above for run %s\n' "$run_id"
    continue
    ;;
  esac
  seen="$seen $run_id"

  log=$(gh run view "$run_id" --log-failed 2>/dev/null || true)
  if [ -z "$log" ]; then
    printf 'log:        empty. The job may have been cancelled before it ran.\n'
    continue
  fi
  printf '\nlast %s lines of the failing steps:\n' "$LOG_LINES"
  printf '%s\n' "$log" | tail -n "$LOG_LINES"
done <<EOF
$failed
EOF

printf '\n--------------------------------------------------------------\n'
printf 'Run the reproducers above before changing anything. A failure that\n'
printf 'does not reproduce locally is a different problem from one that does.\n'
exit 1
