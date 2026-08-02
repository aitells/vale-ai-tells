#!/usr/bin/env bash
# Three-tier format/lint feedback for Claude Code, split by event:
#
#   PostToolUse   — after each Edit/Write/MultiEdit, run FORMATTERS only on the
#                    written file (just format-go / format-markdown). Mutates in
#                    place, never blocks. Keeps the tree formatted as the agent
#                    works; nudges a re-read when the file actually changed.
#
#   PostToolBatch — after each batch, run the LINTERS (just lint-go, lint-prose,
#                    lint-spelling) over the changed files, consolidate the
#                    findings, and surface them as additionalContext with an
#                    imperative directive to fix them all. It can't mechanically
#                    block, but the agent is told to treat it as a required gate
#                    (Stop is the mechanical backstop), not optional feedback.
#
#   Stop          — when the agent tries to finish, run the same linters and
#                    BLOCK if any fail, forcing a fix before it hands back to the
#                    user. The only hard gate, and the right place for one.
#
# Linters are read-only, so a shared content fingerprint lets Stop reuse
# PostToolBatch's result instead of re-linting. Stop blocks with top-level
# decision/reason only (it rejects hookSpecificOutput). Toolchain failures never
# block. Registered locally via .claude/settings.local.json (not committed).
set -euo pipefail
# --- environment hardening -------------------------------------------
# core.quotePath defaults to true, so a path with a non-ASCII character
# arrives as "caf\303\251.go" and every linter downstream is handed a
# filename that does not exist. The locale pin keeps sort -u from
# collapsing two paths that merely collate alike.
#
# ls-files keeps --exclude-standard on purpose: the operator's global
# gitignore legitimately decides what counts as untracked.
export LC_ALL=C
unset CDPATH GREP_OPTIONS
IFS=$(printf ' \t\n')

gitr() {
  command git --no-pager -c core.quotePath=false -c color.ui=false \
    -c log.showSignature=false "$@"
}

# Feed the agent context for its next step (non-blocking), then exit.
emit_context() {
  # shellcheck disable=SC2016  # $ctx/$event are jq variables, set via --arg
  jq -n --arg ctx "$1" --arg event "$event" \
    '{suppressOutput: true, hookSpecificOutput: {hookEventName: $event, additionalContext: $ctx}}'
  exit 0
}

# Block (Stop only): top-level decision/reason — no hookSpecificOutput, which
# Stop rejects (a block carrying it fails open).
emit_block() {
  # shellcheck disable=SC2016  # $reason/$msg are jq variables, set via --arg
  jq -n --arg reason "$1" --arg msg "$2" \
    '{decision: "block", reason: $reason, systemMessage: $msg, suppressOutput: true}'
  exit 0
}

# User-facing notice only (toolchain trouble); never blocks.
emit_skip() {
  # shellcheck disable=SC2016  # $msg is a jq variable, set via --arg
  jq -n --arg msg "$1" '{suppressOutput: true, systemMessage: $msg}'
  exit 0
}

# Run a command, capturing stdout (findings) / stderr (chatter) / rc.
run_recipe() {
  if RUN_STDOUT=$("$@" 2>"$err_file"); then
    RUN_RC=0
  else
    RUN_RC=$?
  fi
  RUN_STDERR=$(cat "$err_file" 2>/dev/null || true)
  rm -f "$err_file"
}

# Toolchain trouble (not real findings) -> skip rather than trap the agent.
is_infra_failure() {
  local blob
  blob=$(printf '%s\n%s' "$1" "$2" | tr '[:upper:]' '[:lower:]')
  case "$blob" in
  *"cannot connect to the docker daemon"* | *"is the docker daemon running"* | \
    *"error during connect"* | *"command not found"* | *"does not contain recipe"* | \
    *"cannot find binary path"* | *"executable file not found"* | \
    *"permission denied while trying to connect"*) return 0 ;;
  *) return 1 ;;
  esac
}

# Distill linter output ($1 stdout, $2 stderr): strip ANSI, drop just's echoed
# commands and golangci runner chatter, bound the size. Prefer stdout.
findings_text() {
  local src=$1 esc
  [[ -z ${1//[[:space:]]/} ]] && src=$2
  esc=$(printf '\033')
  printf '%s\n' "$src" |
    sed -E "s/${esc}\[[0-9;]*[A-Za-z]//g" |
    awk '
      /^level=(warning|info|debug) / { next }
      /^error: Recipe .* failed on line / { next }
      /^go (fix|vet|build|tool) / { next }
      /^(vale|cspell|golangci) / { next }
      /^DOCKER_CONFIG=/ { next }
      { sub(/[ \t\r]+$/, ""); buf[++n] = $0 }
      END {
        for (i = 1; i <= n && i <= 200; i++) print buf[i]
        if (n > 200) printf "... (%d more lines)\n", n - 200
      }
    '
}

# Run one linter and fold any findings into FINDINGS / FOUND. A toolchain
# failure skips the whole hook (non-blocking). $1 = label, rest = command.
lint_with() {
  local label=$1
  shift
  run_recipe "$@"
  is_infra_failure "$RUN_STDOUT" "$RUN_STDERR" &&
    emit_skip "Lint hook skipped: ${label} could not run (toolchain unavailable)."
  if [[ $RUN_RC -ne 0 ]]; then
    FOUND=1
    FINDINGS+="
### ${label}
$(findings_text "$RUN_STDOUT" "$RUN_STDERR")
"
  fi
}

# All non-vendor files that differ from HEAD: tracked edits + brand-new files.
compute_changed() {
  {
    gitr diff --no-ext-diff --name-only HEAD -- . ':(exclude)vendor'
    gitr ls-files --others --exclude-standard -- . ':(exclude)vendor'
  } | sort -u
}

# Hash the content (name + bytes) of the newline-separated file list in $1.
compute_fingerprint() {
  {
    while IFS= read -r f; do
      if [[ -f $f ]]; then
        printf '%s\n' "$f"
        cat -- "$f"
      fi
    done <<<"$1" | shasum -a 256 | cut -d' ' -f1
  } || true
}

# Subset of a newline list ($2) whose entries match ERE $1.
grep_files() { printf '%s\n' "$2" | grep -E "$1" || true; }

input=$(cat)
event=$(jq -r '.hook_event_name // "Stop"' <<<"$input")
session_id=$(jq -r '.session_id // "default"' <<<"$input")
session_id=$(printf '%s' "$session_id" | tr -c 'A-Za-z0-9._-' '_')

project_dir=${CLAUDE_PROJECT_DIR:-$(jq -r '.cwd // "."' <<<"$input")}
cd "$project_dir" || exit 0

git rev-parse --is-inside-work-tree >/dev/null 2>&1 || exit 0
git rev-parse --verify -q HEAD >/dev/null || exit 0

state_dir="tmp/claude-go-hook"
mkdir -p "$state_dir"
err_file="${state_dir}/${session_id}.err"

if ! command -v just >/dev/null 2>&1; then
  emit_skip "Lint hook skipped: \`just\` is not installed."
fi

case "$event" in
PostToolUse)
  # Formatters only, on the written file. Mutates; never blocks.
  file_path=$(jq -r '.tool_input.file_path // ""' <<<"$input")
  [[ -z $file_path ]] && exit 0
  rel=${file_path#"$project_dir"/}
  case "$rel" in
  /* | vendor/*) exit 0 ;; # outside project or vendored
  *.go) recipe=format-go ;;
  *.md) recipe=format-markdown ;;
  *) exit 0 ;; # nothing to format
  esac
  [[ -f $rel ]] || exit 0

  before=$(shasum -a 256 "$rel" 2>/dev/null | cut -d' ' -f1)
  run_recipe just "$recipe" "$rel"
  is_infra_failure "$RUN_STDOUT" "$RUN_STDERR" &&
    emit_skip "Format hook skipped: \`just ${recipe}\` could not run (toolchain unavailable)."
  after=$(shasum -a 256 "$rel" 2>/dev/null | cut -d' ' -f1)

  # Only nudge a re-read when the formatter actually rewrote the file.
  if [[ $before != "$after" ]]; then
    # shellcheck disable=SC2016  # backticks are literal markdown for the agent
    emit_context "$(printf '`just %s` reformatted %s. Re-read it before your next Edit/Write so a stale cached copy does not fail the write.' "$recipe" "$rel")"
  fi
  exit 0
  ;;

PostToolBatch | Stop)
  # Linters over the changed files. PostToolBatch surfaces findings as context;
  # Stop blocks on them. Read-only, so the two share one fingerprint cache.
  changed=$(compute_changed)
  [[ -z $changed ]] && exit 0
  fingerprint=$(compute_fingerprint "$changed")
  state_file="${state_dir}/${session_id}.findings"

  if [[ -n $fingerprint && -f $state_file ]]; then
    cached_fp=$(jq -r '.fingerprint // ""' "$state_file" 2>/dev/null || true)
    if [[ $cached_fp == "$fingerprint" ]]; then
      cached_findings=$(jq -r '.findings // ""' "$state_file" 2>/dev/null || true)
      if [[ -n ${cached_findings//[[:space:]]/} && $event == Stop ]]; then
        emit_block "Lint findings must be resolved before finishing — fix these, then the hook re-runs:
${cached_findings}" "Lint gate: findings to fix before finishing."
      fi
      exit 0 # PostToolBatch already surfaced these; clean trees just pass
    fi
  fi

  FINDINGS=""
  FOUND=0
  go_changed=$(grep_files '\.go$' "$changed")
  golangci_changed=$(grep_files '(^|/)\.golangci\.yml$' "$changed")
  prose_changed=$(grep_files '\.(md|go)$' "$changed")

  if [[ -n $go_changed || -n $golangci_changed ]]; then
    lint_with "Go — just lint-go" just lint-go
  fi
  if [[ -n $prose_changed ]]; then
    prose_args=()
    while IFS= read -r f; do [[ -n $f ]] && prose_args+=("$f"); done <<<"$prose_changed"
    lint_with "Prose — just lint-prose" just lint-prose "${prose_args[@]}"
  fi
  spell_args=()
  while IFS= read -r f; do [[ -n $f ]] && spell_args+=("$f"); done <<<"$changed"
  lint_with "Spelling — just lint-spelling" just lint-spelling "${spell_args[@]}"

  # shellcheck disable=SC2016  # $fp/$f are jq variables, set via --arg
  jq -n --arg fp "$fingerprint" --arg f "$FINDINGS" '{fingerprint: $fp, findings: $f}' >"$state_file" 2>/dev/null || true

  if [[ $FOUND -eq 1 ]]; then
    if [[ $event == Stop ]]; then
      emit_block "Lint findings must be resolved before finishing — fix these, then the hook re-runs:
${FINDINGS}" "Lint gate: findings to fix before finishing."
    fi
    emit_context "You must fix every lint finding below before continuing. This is a required gate, not optional feedback: do not move on to other work, and do not finish, until they are all resolved.
${FINDINGS}"
  fi
  exit 0
  ;;

*)
  exit 0
  ;;
esac
