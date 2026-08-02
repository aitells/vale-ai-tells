#!/usr/bin/env bash
# guard-resolve — PreToolUse gate on Bash, scoped to the conflict
# resolution skill.
#
# The skill body already states these rules. This hook is what makes
# them hold: instructions degrade under a long context, an exit-2 deny
# does not.
#
# Three rules:
#
#   1. `--ours` and `--theirs` are refused, on checkout and restore
#      alike. During a rebase they mean the opposite of what the words
#      suggest, and getting them backwards resolves the file to the
#      wrong content with no error and no symptom until much later.
#      take-side.sh takes the same decision under names that survive
#      being read quickly.
#   2. Staging a path that still carries conflict markers is refused.
#      git will stage it, `git rebase --continue` will commit it, and
#      the markers surface days later inside a file nobody was looking
#      at.
#   3. Whole-tree staging is refused. A conflict resolution stages the
#      paths it resolved; a wildcard sweeps in whatever else the
#      worktree is carrying, and during a rebase that includes files an
#      earlier commit in the replay left behind.
#
# Exit 2 blocks and hands stderr back as the reason. Exit 0 defers to
# the normal permission flow.
set -euo pipefail

# --- environment hardening -------------------------------------------
# The agent reads this output, so the operator's preferences must not
# change its shape. LC_ALL pins the [a-z] ranges the patterns below use.
export LC_ALL=C
export PYTHONUTF8=1
unset CDPATH GH_REPO GH_HOST GREP_OPTIONS
IFS=$(printf ' \t\n')

payload=$(cat)
command=$(jq -r '.tool_input.command // ""' <<<"$payload")

deny() {
  printf 'Blocked by the resolve-rebase-conflicts skill guard.\n\n%s\n' "$1" >&2
  exit 2
}

# Heredoc bodies are data, not commands. A script written through a
# heredoc can discuss staging in its comments or its prose, and matching
# that text refuses a command that never touched the index.
command=$(printf '%s' "$command" | awk '
  {
    if (term != "") {
      line = $0
      sub(/^[ \t]+/, "", line)
      if (line == term) { term = "" }
      next
    }
    rest = $0
    while (match(rest, /<<-?[ \t]*["'"'"']?[A-Za-z_][A-Za-z0-9_]*["'"'"']?/)) {
      word = substr(rest, RSTART, RLENGTH)
      rest = substr(rest, RSTART + RLENGTH)
      gsub(/^<<-?[ \t]*|["'"'"']/, "", word)
      term = word
    }
    print
  }
')

readonly AT_START=$'(^|[;&|(]|&&|\\|\\||\n)[[:space:]]*'
readonly GIT_CMD='git([[:space:]]+-[cC][[:space:]]+[^[:space:]]+)*[[:space:]]+'

if ! [[ $command =~ ${AT_START}${GIT_CMD}(add|checkout|restore|checkout-index) ]]; then
  exit 0
fi

# Rule 1: the two inverted words.
if [[ $command =~ ${AT_START}${GIT_CMD}(checkout|restore|checkout-index)[^\&\;\|]*(--ours|--theirs|--stage=[23]) ]]; then
  deny "During a rebase --ours is the branch being replayed onto and --theirs is
the commit being replayed, which is the reverse of how both words read.
A wrong pick here resolves cleanly and stays wrong.

Name the side instead:

  bash .claude/skills/resolve-rebase-conflicts/scripts/take-side.sh <path> base-side
  bash .claude/skills/resolve-rebase-conflicts/scripts/take-side.sh <path> replayed-side

It prints which commit each side is before it acts, and it stages the
result. For an append-only sorted file, neither side is the answer:

  bash .claude/skills/resolve-rebase-conflicts/scripts/resolve-union.sh <path>"
fi

[[ $command =~ ${AT_START}${GIT_CMD}add ]] || exit 0

# Rule 3: no wildcard staging.
if [[ $command =~ ${AT_START}${GIT_CMD}add([[:space:]]+-[^[:space:]]*)*[[:space:]]+(-A|--all)([[:space:]]|$) ]] ||
  [[ $command =~ ${AT_START}${GIT_CMD}add([[:space:]]+-[^[:space:]]*)*[[:space:]]+\.([[:space:]]|$) ]]; then
  deny "Whole-tree staging during a rebase sweeps in more than the conflict.
Stage the paths you resolved, by name:

  git add -- path/one path/two"
fi

# Rule 2: no markers in what gets staged.
#
# Arguments are read off the add invocation alone, stopping at the next
# shell separator, so a path mentioned later in a pipeline is not
# mistaken for one being staged. Only the two directional markers count:
# a bare ======= line opens no conflict and closes none, and it is an
# ordinary Markdown setext heading underline.
if [[ $command =~ (${GIT_CMD}add[^\&\;\|]*) ]]; then
  invocation=${BASH_REMATCH[1]}
else
  exit 0
fi

# A file whose subject is conflict markers carries them legitimately.
# This skill's own SKILL.md documents the marker shape by showing it,
# and it ships into every repository the package installs into, so the
# exemption is built in rather than left to each consumer to discover.
# Anything else declares itself with `conflict-markers=documented` in
# .gitattributes. marker-scan.sh in the rebase skill applies the same
# rule; a guard stays self-contained rather than reaching across skills
# for it, because a guard that cannot run is a guard that cannot refuse.
documented() {
  case $1 in
  */skills/resolve-rebase-conflicts/SKILL.md | skills/resolve-rebase-conflicts/SKILL.md)
    return 0
    ;;
  esac
  [ "$(git check-attr conflict-markers -- "$1" 2>/dev/null | sed 's/.*: //')" = documented ]
}

offenders=""
# shellcheck disable=SC2086  # word splitting is the point: these are argv
for arg in $invocation; do
  case $arg in
  git | add | -*) continue ;;
  esac
  [ -f "$arg" ] || continue
  documented "$arg" && continue
  if grep -qE '^(<<<<<<<|>>>>>>>|\|\|\|\|\|\|\|)( |$)' "$arg" 2>/dev/null; then
    offenders="${offenders}  ${arg}
"
  fi
done

if [ -n "$offenders" ]; then
  deny "These still carry conflict markers:

${offenders}
git stages them without complaint and the rebase commits them. Finish the
resolution first: open each file, remove every <<<<<<< / ||||||| / >>>>>>>
line along with the side that loses, and stage it then.

classify-conflicts.sh prints what each side was changing, which is the
part the markers do not show."
fi

exit 0
