#!/usr/bin/env bash
# check-suppressions — refuse to let a lint finding be cleared by
# changing the rules instead of the prose.
#
# A rule that can't be met is a genuine outcome here, and the fixer is
# told to report one rather than invent text. What must never happen
# instead is clearing the finding by changing the rules: an edit
# to .vale.ini, a word appended to the project vocabulary, an inline
# `vale off` comment, a rewritten style file. Every one of those
# produces a clean lint run over a document nobody actually fixed.
#
# Instructions alone don't prevent it. The delegated writer can edit a
# style file, so this script is the mechanical answer. It deliberately
# runs from the parent after delegation: an agent certifying its own
# work certifies nothing.
#
# Two modes, one definition of the guarded set, so the two halves stay
# consistent:
#
#   --baseline <target>   record the state before the fixer runs and print
#                         the unique state directory.
#   --verify <state> <target>
#                         compare against that baseline afterwards.
#   --diff <state> <target>
#                         print what the fixer changed, for the reviewer.
#   --cleanup <state>     remove a completed workflow's state.
#
# The synced vale style packages are why the configuration half hashes
# files directly rather than asking git. .gitignore excludes .vale/* apart
# from the project styles, so an edit to .vale/ai-tells/VerbTricolon.yml
# never shows up in git status. This repository already knows that rule
# misfires, which makes it the first file an agent would edit when no
# wording change clears the finding.
#
# Findings print one per line in the shape the vale template uses.
# Silence means a clean run, and the exit code carries the result.
#
# A missing baseline is a finding rather than a pass. A check that
# reports zero has more likely failed to run than found nothing.
set -euo pipefail

# --- environment hardening -------------------------------------------
# The agent reads this output, so the operator's preferences must not
# change its shape. LC_ALL pins collation, because the sorts below mean
# different things under a UTF-8 locale. CDPATH is unset because it
# makes a relative path resolve somewhere else entirely.
export LC_ALL=C
unset CDPATH GREP_OPTIONS
IFS=$' \t\n'

# gitr runs git for output this script parses, with the formatting knobs
# pinned. core.quotePath matters most here: a non-ASCII path comes back
# octal-escaped by default, so it would never match the same path read
# off disk.
gitr() {
  command git --no-pager \
    -c core.quotePath=false \
    -c color.ui=false -c color.diff=false -c color.status=false \
    -c diff.noprefix=false -c diff.mnemonicPrefix=false \
    "$@"
}

# Linter configuration outside .vale/. Changing any of these clears a
# finding by changing the rules rather than the prose. Justfile stays
# alongside mise.toml for a consumer that has not retired its own; a
# name absent from the tree costs nothing to watch.
readonly CONFIG_FILES=(
  .vale.ini
  .cspell.jsonc
  .cspell-words.txt
  .pre-commit-config.yaml
  mise.toml
  Justfile
)

# Comment forms that silence a checker in place. The vale pattern
# covers both the block toggle and a per-rule override.
readonly DIRECTIVES='vale[[:space:]]+(off|on)|vale[[:space:]]+[A-Za-z][A-Za-z0-9._-]*[[:space:]]*=[[:space:]]*([Nn][Oo]|off)|cspell:|cSpell:|spell-checker:|markdownlint-disable|rumdl-disable'

root=$(git rev-parse --show-toplevel)
git_dir=$(git rev-parse --absolute-git-dir)
cd "$root"
root=$(pwd -P)

readonly BASE_ROOT="$git_dir/fix-prose"

canonical_target() {
  local target=$1 target_dir
  target_dir=$(cd -- "$(dirname -- "$target")" 2>/dev/null && pwd -P) || target_dir=
  if [ -n "$target_dir" ]; then
    target="$target_dir/$(basename -- "$target")"
  fi
  case $target in
  "$root"/*) target=${target#"$root"/} ;;
  esac
  printf '%s\n' "$target"
}

load_state() {
  local state=${1:-}
  case $state in
  "$BASE_ROOT"/run.*) ;;
  *)
    printf 'check-suppressions: invalid workflow state: %s\n' "${state:-(none)}" >&2
    exit 2
    ;;
  esac
  [ -s "$state/target" ] || {
    printf 'check-suppressions: workflow state is missing its target: %s\n' "$state" >&2
    exit 2
  }
  printf '%s\n' "$state"
}

check_target() {
  local state=$1 supplied=${2:-} expected
  [ -n "$supplied" ] || return 0
  expected=$(head -1 "$state/target")
  supplied=$(canonical_target "$supplied")
  [ "$supplied" = "$expected" ] || {
    printf 'check-suppressions: state belongs to %s, not %s\n' "$expected" "$supplied" >&2
    exit 2
  }
}

# digest prints one "<sha>  <path>" line per file worth watching, sorted
# by path. The target is left out of both halves, because editing it is
# the entire job.
digest() {
  local target=$1
  {
    # A while-read loop rather than find -exec: the skill scanner
    # refuses -exec at high severity, and the hashes come out the same.
    local vf
    while IFS= read -r -d '' vf; do
      shasum -a 256 "$vf"
    done < <(find .vale -type f -print0 2>/dev/null) || true

    local f
    for f in "${CONFIG_FILES[@]}"; do
      [ -f "$f" ] && shasum -a 256 "$f"
    done

    # Everything else the fixer could have touched. Tracked files show
    # up through the diff, and anything new through ls-files.
    {
      gitr diff --no-ext-diff HEAD --name-only
      gitr ls-files --others --exclude-standard
    } | sort -u | while IFS= read -r f; do
      if [ -f "$f" ] || [ -L "$f" ]; then
        shasum -a 256 "$f"
      elif [ -n "$f" ]; then
        printf '%064d  %s\n' 0 "$f"
      fi
    done
  } | sort -u -k2 |
    awk -v t="$target" '{p = $0; sub(/^[0-9a-f]+  /, "", p); if (p != t) print}'
}

# directives prints the suppression comments already in the target, so
# a document that legitimately carries one doesn't read as a new find.
directives() {
  local target=$1
  [ -f "$target" ] || return 0
  grep -nE "$DIRECTIVES" "$target" || true
}

mode=${1:-}

case $mode in
--baseline)
  target=${2:-}
  [ -n "$target" ] || {
    printf 'check-suppressions: --baseline needs a target path\n' >&2
    exit 2
  }
  target=$(canonical_target "$target")
  mkdir -p "$BASE_ROOT"
  target_key=$(printf '%s' "$target" | shasum -a 256 | cut -d' ' -f1)
  BASE="$BASE_ROOT/run.$target_key"
  mkdir "$BASE" 2>/dev/null || {
    printf 'check-suppressions: an active workflow already owns %s\n' "$target" >&2
    exit 2
  }
  printf '%s\n' "$target" >"$BASE/target"
  digest "$target" >"$BASE/digest"
  directives "$target" >"$BASE/directives"
  # A copy of the document before the fixer touched it. The reviewer
  # judges whether the meaning survived, which takes both versions, and
  # the file is gitignored often enough that git can't supply the first.
  [ -f "$target" ] && cp "$target" "$BASE/original"
  printf 'state: %s\n' "$BASE"
  ;;

--verify)
  BASE=$(load_state "${2:-}")
  check_target "$BASE" "${3:-}"
  findings=0
  report() {
    printf '%s:%s [error] %s  %s\n' "$1" "$2" "$3" "$4"
    findings=$((findings + 1))
  }

  if [ ! -s "$BASE/target" ]; then
    report "${BASE#"$root"/}" 1 no-baseline \
      "no fix-prose baseline recorded, so nothing here was verified; re-run the skill rather than reading this as a pass"
    printf 'TOTAL: %s finding(s)\n' "$findings"
    exit 1
  fi
  target=$(head -1 "$BASE/target")

  now=$(mktemp)
  trap 'rm -f "$now"' EXIT
  digest "$target" >"$now"

  # A path whose hash changed, or one that appeared, or one that was
  # removed. All three mean the fixer edited something other than the
  # document it was given.
  while IFS= read -r path; do
    [ -n "$path" ] || continue
    case $path in
    .vale/* | .vale.ini | .cspell* | .pre-commit-config.yaml | mise.toml | Justfile)
      report "$path" 1 linter-config-changed \
        "the fixer changed linter configuration, which clears findings by changing the rules rather than the prose; revert it and record the finding as unresolved"
      ;;
    *)
      report "$path" 1 stray-edit \
        "the fixer edited a file other than its target; only the target was in scope"
      ;;
    esac
  done < <(
    diff "$BASE/digest" "$now" |
      sed -n 's/^[<>] [0-9a-f]\{64\}  //p' | sort -u || true
  )

  # Suppression comments the target didn't carry before.
  while IFS= read -r line; do
    [ -n "$line" ] || continue
    report "$target" "${line%%:*}" suppression-comment \
      "the fixer added a comment silencing a checker in place: ${line#*:}"
  done < <(
    directives "$target" |
      grep -vxF -f "$BASE/directives" 2>/dev/null || true
  )

  if [ "$findings" -gt 0 ]; then
    printf 'TOTAL: %s finding(s)\n' "$findings"
    exit 1
  fi
  ;;

--diff)
  BASE=$(load_state "${2:-}")
  check_target "$BASE" "${3:-}"
  # What the fixer changed, for the reviewer to read. Prints nothing
  # when the document came back byte for byte identical.
  [ -s "$BASE/target" ] || {
    printf 'check-suppressions: no baseline recorded\n' >&2
    exit 2
  }
  target=$(head -1 "$BASE/target")
  [ -f "$BASE/original" ] || {
    printf 'check-suppressions: baseline kept no copy of %s\n' "$target" >&2
    exit 2
  }
  diff -u "$BASE/original" "$target" || true
  ;;

--cleanup)
  BASE=$(load_state "${2:-}")
  rm -rf "$BASE"
  ;;

*)
  printf 'usage: check-suppressions.sh --baseline <target> | --verify <state> <target> | --diff <state> <target> | --cleanup <state>\n' >&2
  exit 2
  ;;
esac
