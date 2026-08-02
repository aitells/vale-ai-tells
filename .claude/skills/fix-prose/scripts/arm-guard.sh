#!/usr/bin/env bash
# arm-guard — PostToolUse on Skill, recording which file fix-prose was
# given, so guard-target.sh knows what to refuse.
#
# The guard has to name one path, and only the invocation knows it. The
# Skill payload carries the arguments verbatim, so the first word of
# them is the target, resolved against the payload's own cwd rather than
# against wherever this process happens to start.
#
# Verified against Claude Code 2.1.220 with a throwaway project: a
# PostToolUse hook declared in a skill's own frontmatter DOES fire for
# that skill's own invocation, and the payload carries tool_input.skill
# plus tool_input.args. The published reference describes a
# tool_input.skill_name instead, which this version never sends.
#
# That probe also settled why fix-prose is not a `context: fork` skill.
# A forked skill's frontmatter hooks register nowhere: the caller's
# session never sees them, which is why the pull request guard is
# declared by `pr` rather than by write-pr-description. A plain skill's
# hooks do register, they fire for the caller's own tool calls, and they
# stay silent for an Agent-tool subagent's. That is exactly the scoping
# a guard here needs, so the skill body spawns the fixer through the
# Agent tool and leaves its own frontmatter plain.
#
# The lock lives under the git directory, which is per-worktree, and it
# holds a single slot that each invocation overwrites. It affects one
# path for the rest of the session, because a skill's hooks stop firing
# once the session ends and a leftover file then guards nothing.
#
# Never blocks. A PostToolUse hook that fails would only obstruct the
# invocation it exists to protect.
set -euo pipefail

# --- environment hardening -------------------------------------------
# LC_ALL pins collation for the git call below, and CDPATH is unset
# because it makes a relative path resolve somewhere else entirely.
export LC_ALL=C
unset CDPATH GREP_OPTIONS
IFS=$(printf ' \t\n')

payload=$(cat)

skill=$(jq -r '.tool_input.skill // ""' <<<"$payload")
[ "$skill" = "fix-prose" ] || exit 0

# Every skill invoked while these hooks are live reaches this script, so
# the name check above matters: without it a later Skill call would
# overwrite the lock with its own arguments.
args=$(jq -r '.tool_input.args // ""' <<<"$payload")
target=${args%%[[:space:]]*}
[ -n "$target" ] || exit 0

cwd=$(jq -r '.cwd // ""' <<<"$payload")
[ -d "$cwd" ] || exit 0

case $target in
/*) abs=$target ;;
*) abs=$cwd/$target ;;
esac

# An argument naming something absent is a caller error rather than a
# target. Arming on it would refuse edits to a path nobody is fixing.
[ -f "$abs" ] || exit 0

git_dir=$(command git -C "$cwd" rev-parse --absolute-git-dir 2>/dev/null) || exit 0

printf '%s\n' "$abs" >"$git_dir/fix-prose.lock"

# Record what the linter configuration looks like before the fixer runs.
# The fixer works unguarded inside its fork, so nothing in the harness
# stops it from clearing a finding by editing a style file instead of
# the prose. check-suppressions.sh --verify reads this afterwards, on
# the caller's side, and a missing baseline reads as a finding there
# rather than as a pass.
#
# Failure stays silent for the same reason the rest of this hook does.
# Obstructing the invocation would cost more than the check is worth,
# and the absent baseline already surfaces at verify time.
script_dir=$(cd -- "$(dirname -- "$0")" && pwd)
(cd "$cwd" && "$script_dir/check-suppressions.sh" --baseline "$abs") 2>/dev/null || true
