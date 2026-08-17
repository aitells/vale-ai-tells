#!/usr/bin/env bash
# validate-description — mechanical checks on a drafted pull request
# description.
#
# The draft lives at the repository root as PR_AGENTDESC.md and carries
# three things the template cannot: YAML frontmatter holding the pull
# request properties, a level 1 heading holding the title, and the
# template's sections filled in.
#
# Every rule here settles a question by looking, never by judging. The
# frontmatter parses and names known keys. The title fits the shape a
# squash merge needs. The template's sections are present, in order, and
# carry content. No instructional comment survived. No fence hangs open.
# Every path the description puts in backticks exists in the tree or in
# the diff. Whether the prose is true, or worth reading, belongs to
# review-pr-description instead.
#
# Findings print one per line, each self-contained, in the shape the
# repository's vale template uses. Silence means a clean run and the
# exit code carries the result.
#
# Written to bash 3.2 so it runs on a stock macOS shell: no mapfile, no
# associative arrays, no process substitution, no GNU-only sed.
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

DRAFT=${1:-PR_AGENTDESC.md}
TEMPLATE=${PR_TEMPLATE:-.github/pull_request_template.md}

# Title bounds mirror the commit subject bounds, because a squash merge
# turns this title into that subject.
TITLE_MIN=${PR_TITLE_MIN_LENGTH:-10}
TITLE_MAX=${PR_TITLE_MAX_LENGTH:-80}

# The frontmatter keys this workflow understands. Anything else is a
# typo or an invention, and gh would ignore it either way.
readonly REQUIRED_KEYS="base draft labels"
readonly OPTIONAL_KEYS="reviewers assignees milestone"
readonly SEQUENCE_KEYS="labels reviewers assignees"

root=$(git rev-parse --show-toplevel)
cd "$root"

findings=0

report() {
  printf '%s:%s [error] %s  %s\n' "$DRAFT" "$1" "$2" "$3"
  findings=$((findings + 1))
}

# fatal covers the cases that leave nothing further to check.
fatal() {
  report "$1" "$2" "$3"
  printf 'TOTAL: %s finding(s) in %s\n' "$findings" "$DRAFT"
  exit 1
}

[ -e "$DRAFT" ] || fatal 0 missing-draft "no draft at this path; draft the description first"
[ -s "$DRAFT" ] || fatal 0 empty-draft "the draft is empty"
[ -f "$TEMPLATE" ] ||
  fatal 0 missing-template "no pull request template at ${TEMPLATE}; nothing to validate against"

# contains reports whether word $2 appears in the space-separated list
# $1, without matching a shorter key as a substring.
contains() {
  case " $1 " in
  *" $2 "*) return 0 ;;
  *) return 1 ;;
  esac
}

# line_of prints the draft line a given level 2 heading sits on, or 0
# when the draft never declared it. Findings carry a line so that fixing
# one means opening the draft at that point rather than searching it.
line_of() {
  awk -v want="$1" '
    { at = index($0, ":"); if (at && substr($0, at + 1) == want) { print substr($0, 1, at - 1); exit } }
    END { }
  ' <<EOF
${section_index}
EOF
}

# The template's level 2 headings, in order, are the required sections.
required=$(grep '^## ' "$TEMPLATE" || true)
[ -n "$required" ] ||
  fatal 0 template-has-no-sections "${TEMPLATE} declares no level 2 headings"

# ---------------------------------------------------------------------
# One pass: frontmatter, headings, title, empty sections, comments
# ---------------------------------------------------------------------

line_no=0
fm_open=0
fm_close=0
fm_keys=""
fm_base=""
fm_base_line=0
fm_labels=""
fm_labels_line=0
title_line=0
title_text=""
extra_titles=""
draft_sections=""
section_index=""
empty_sections=""
comment_lines=""
cur_head=""
cur_head_line=0
cur_depth=0
cur_saw_body=0

# close_section records a section that never received content.
close_section() {
  if [ -n "$cur_head" ] && [ "$cur_saw_body" = 0 ]; then
    empty_sections="${empty_sections}${cur_head_line}:${cur_head}
"
  fi
}

while IFS= read -r line || [ -n "$line" ]; do
  line_no=$((line_no + 1))

  # Frontmatter runs from a delimiter on line 1 to the next one.
  if [ "$line" = "---" ]; then
    if [ "$line_no" = 1 ]; then
      fm_open=$line_no
      continue
    elif [ "$fm_open" != 0 ] && [ "$fm_close" = 0 ]; then
      fm_close=$line_no
      continue
    fi
  fi

  if [ "$fm_open" != 0 ] && [ "$fm_close" = 0 ]; then
    case $line in
    '' | '#'*) ;;
    *:*)
      key=${line%%:*}
      value=${line#*:}
      value=${value# }
      fm_keys="${fm_keys}${key} "
      if ! contains "$REQUIRED_KEYS $OPTIONAL_KEYS" "$key"; then
        report "$line_no" frontmatter-unknown-key \
          "\"${key}\" is not a pull request property this workflow sets"
      elif contains "$SEQUENCE_KEYS" "$key"; then
        case $value in
        '['*']')
          if [ "$key" = labels ]; then
            fm_labels=$value
            fm_labels_line=$line_no
          fi
          ;;
        *)
          report "$line_no" frontmatter-not-a-sequence \
            "\"${key}\" takes a flow sequence such as [one, two] or []"
          ;;
        esac
      elif [ "$key" = draft ]; then
        case $value in
        true | false) ;;
        *)
          report "$line_no" frontmatter-not-a-boolean \
            "\"draft\" takes true or false, not \"${value}\""
          ;;
        esac
      elif [ "$key" = base ]; then
        fm_base=$value
        fm_base_line=$line_no
        if [ -z "$value" ]; then
          report "$line_no" frontmatter-empty-base "\"base\" needs the branch this merges into"
        fi
      fi
      ;;
    *)
      report "$line_no" frontmatter-unparsed "expected a \"key: value\" line, found \"${line}\""
      ;;
    esac
    continue
  fi

  case $line in
  '#'*' '*)
    # Heading depth is the run of leading number signs.
    marker=${line%% *}
    depth=${#marker}
    if [ "$cur_depth" != 0 ] && [ "$depth" -gt "$cur_depth" ]; then
      # A deeper heading is content belonging to the open section.
      cur_saw_body=1
    else
      close_section
      cur_head=""
      cur_depth=0
    fi
    if [ "$depth" = 1 ]; then
      if [ "$title_line" = 0 ]; then
        title_line=$line_no
        title_text=${line#\# }
      else
        extra_titles="${extra_titles}${line_no} "
      fi
    elif [ "$depth" = 2 ]; then
      draft_sections="${draft_sections}${line}
"
      section_index="${section_index}${line_no}:${line}
"
      cur_head=$line
      cur_head_line=$line_no
      cur_depth=$depth
      cur_saw_body=0
    fi
    ;;
  '') ;;
  *) cur_saw_body=1 ;;
  esac

  case $line in
  *'<!--'*) comment_lines="${comment_lines}${line_no} " ;;
  esac
done <"$DRAFT"
close_section

# The prose is everything past the frontmatter. The rules below read
# that rather than the whole file, so a label spelled "todo" stays
# innocent.
if [ "$fm_close" != 0 ]; then
  prose=$(sed -n "$((fm_close + 1)),\$p" "$DRAFT")
else
  prose=$(cat "$DRAFT")
fi

# ---------------------------------------------------------------------
# Frontmatter
# ---------------------------------------------------------------------

if [ "$fm_open" = 0 ]; then
  report 1 frontmatter-missing \
    "the draft opens without YAML frontmatter carrying the pull request properties"
elif [ "$fm_close" = 0 ]; then
  report 1 frontmatter-unterminated "the frontmatter never closes with ---"
else
  for key in $REQUIRED_KEYS; do
    if ! contains "$fm_keys" "$key"; then
      report "$fm_open" frontmatter-missing-key "the frontmatter sets no \"${key}\""
    fi
  done
fi

# An unlabelled pull request lands in nobody's filter. Preflight prints
# the repository's label set, so picking one costs a moment.
if contains "$fm_keys" labels; then
  case $fm_labels in
  '' | '[]' | '[ ]')
    report "$fm_labels_line" labels-empty \
      "the pull request carries no label; preflight printed the repository's label set"
    ;;
  esac
fi

# A base naming no ref fails at creation time, and a base equal to the
# branch fails more confusingly than that.
if [ -n "$fm_base" ]; then
  if ! git rev-parse --verify --quiet "refs/heads/$fm_base" >/dev/null &&
    ! git rev-parse --verify --quiet "refs/remotes/origin/$fm_base" >/dev/null; then
    report "$fm_base_line" base-unknown "\"${fm_base}\" names no local or origin branch"
  elif [ "$fm_base" = "$(git rev-parse --abbrev-ref HEAD)" ]; then
    report "$fm_base_line" base-is-head "\"${fm_base}\" is the branch this pull request comes from"
  fi
fi

# ---------------------------------------------------------------------
# Title
# ---------------------------------------------------------------------

if [ "$title_line" = 0 ]; then
  report "$((fm_close + 1))" title-missing \
    "the draft carries no level 1 heading; the title belongs on the first line after the frontmatter"
else
  for extra in $extra_titles; do
    report "$extra" title-repeated "a second level 1 heading; the title is the first one alone"
  done
  case $title_text in
  *.)
    report "$title_line" title-trailing-period "the title ends in a period"
    ;;
  esac
  case $title_text in
  *'(#'[0-9]*')')
    report "$title_line" title-carries-number \
      "GitHub appends the pull request number on merge, so the title should not carry one"
    ;;
  esac
  if [ "${#title_text}" -lt "$TITLE_MIN" ]; then
    report "$title_line" title-too-short "the title runs under ${TITLE_MIN} characters"
  elif [ "${#title_text}" -gt "$TITLE_MAX" ]; then
    report "$title_line" title-too-long "the title runs past ${TITLE_MAX} characters"
  fi
  if printf '%s' "$title_text" | grep -Eq '^[a-z]+(\([a-zA-Z0-9_./-]+\))?!?: .+'; then
    # The type has to be one the landing commits already use. A branch
    # of documentation commits under a feature title misreports itself
    # in the changelog the moment it squashes.
    title_type=${title_text%%:*}
    title_type=${title_type%%\(*}
    title_type=${title_type%!}
    if [ -n "$fm_base" ] && git rev-parse --verify --quiet "$fm_base" >/dev/null; then
      landing_types=$(gitr log --format='%s' "$fm_base..HEAD" |
        sed -n 's/^\([a-z][a-z]*\)[(!:].*/\1/p' | sort -u | tr '\n' ' ')
      if [ -n "$landing_types" ] && ! contains "$landing_types" "$title_type"; then
        report "$title_line" title-type-unused \
          "no commit that lands is a \"${title_type}\"; they are: ${landing_types% }"
      fi
    fi
  else
    report "$title_line" title-not-conventional \
      "a squash merge makes this title the commit subject, so it needs the <type>(<scope>)?: <description> shape"
  fi
fi

# ---------------------------------------------------------------------
# Sections
# ---------------------------------------------------------------------

# Walk the template's headings against the draft's. A missing heading
# and a reordered one are different mistakes, so the report says which.
present_ordered=""
anchor_head=""
anchor_line=$title_line
while IFS= read -r want; do
  [ -n "$want" ] || continue
  if printf '%s' "$draft_sections" | grep -qxF "$want"; then
    present_ordered="${present_ordered}${want}
"
    anchor_head=$want
    anchor_line=$(line_of "$want")
  elif [ -n "$anchor_head" ]; then
    report "$anchor_line" section-missing \
      "the draft has no \"${want}\" section; the template puts it after \"${anchor_head}\""
  else
    report "$anchor_line" section-missing \
      "the draft has no \"${want}\" section; the template opens with it"
  fi
done <<EOF
$required
EOF

draft_ordered=""
while IFS= read -r have; do
  [ -n "$have" ] || continue
  if printf '%s' "$required" | grep -qxF "$have"; then
    draft_ordered="${draft_ordered}${have}
"
  fi
done <<EOF
$draft_sections
EOF

if [ "$draft_ordered" != "$present_ordered" ]; then
  wanted=$(printf '%s' "$present_ordered" | tr '\n' '|' | sed 's/|$//; s/## //g; s/|/, /g')
  first_wrong=$(printf '%s' "$draft_ordered" | head -1)
  report "$(line_of "$first_wrong")" section-order \
    "the template's sections run in this order: ${wanted}"
fi

while IFS= read -r entry; do
  [ -n "$entry" ] || continue
  entry_line=${entry%%:*}
  entry_head=${entry#*:}
  if printf '%s' "$required" | grep -qxF "$entry_head"; then
    report "$entry_line" section-empty "\"${entry_head}\" has no content under it"
  fi
done <<EOF
$empty_sections
EOF

# A section asking what the author ran wants a command, and a command
# arrives in backticks or a fence. Prose alone reports nothing runnable.
while IFS= read -r head; do
  [ -n "$head" ] || continue
  name=$(printf '%s' "${head#\#\# }" | tr '[:upper:]' '[:lower:]')
  case $name in
  verification | testing | 'test plan' | 'how to test') ;;
  *) continue ;;
  esac
  if ! printf '%s' "$draft_sections" | grep -qxF "$head"; then
    continue
  fi
  section=$(awk -v want="$head" '
    /^#{1,2} / { inside = ($0 == want); next }
    inside { print }
  ' "$DRAFT")
  case $section in
  *'`'*) ;;
  *)
    report "$(line_of "$head")" verification-names-no-command \
      "\"${head}\" names no command; put what you ran in backticks"
    ;;
  esac
done <<EOF
$required
EOF

# ---------------------------------------------------------------------
# Prose
# ---------------------------------------------------------------------

for at in $comment_lines; do
  report "$at" template-comment-left \
    "an instructional comment survived into the description; replace it with prose"
done

placeholders=$(printf '%s\n' "$prose" | grep -n -E '\b(TODO|TBD|FIXME|XXX)\b' | cut -d: -f1 || true)
for at in $placeholders; do
  report "$((at + fm_close))" placeholder-left \
    "a placeholder marker reached the description; resolve it or drop the sentence"
done

dead_links=$(printf '%s\n' "$prose" |
  grep -n -E '\]\((#|TODO|url|link|https?://example\.(com|org))?\)' | cut -d: -f1 || true)
for at in $dead_links; do
  report "$((at + fm_close))" link-placeholder \
    "a link points nowhere; give it a real target or drop it"
done

# An unclosed fence swallows the rest of the description when GitHub
# renders it.
fences=$(printf '%s\n' "$prose" | grep -c '^[[:space:]]*```' || true)
if [ $((fences % 2)) != 0 ]; then
  last_fence=$(printf '%s\n' "$prose" | grep -n '^[[:space:]]*```' | tail -1 | cut -d: -f1)
  report "$((last_fence + fm_close))" fence-unclosed "this fence opens a block that never closes"
fi

# Every path the description puts in backticks exists in the tree or in
# the diff. This is the one truthfulness rule a machine can settle: an
# invented path is invented whatever the surrounding prose claims.
if [ -n "$fm_base" ] && git rev-parse --verify --quiet "$fm_base" >/dev/null; then
  changed=$(gitr diff --no-ext-diff --name-only "$fm_base...HEAD" 2>/dev/null || true)
else
  changed=""
fi

# Match code spans one line at a time. Splitting the whole text on
# backticks and taking alternate fields loses the pairing the moment a
# three-backtick fence throws the parity off.
# shellcheck disable=SC2016  # the backticks are the pattern, not a substitution
tokens=$(printf '%s\n' "$prose" | grep -o '`[^`]*`' | tr -d '`' |
  grep -E '^[A-Za-z0-9._][A-Za-z0-9._/-]*$' | grep '/' | sort -u || true)

for token in $tokens; do
  # A repository reference such as owner/name is not a path, and neither
  # is a directory outside this tree. Look only at tokens carrying an
  # extension or a first segment that exists here.
  base_name=${token##*/}
  head_seg=${token%%/*}
  case $base_name in
  *.*) ;;
  *)
    if [ ! -e "$head_seg" ]; then
      continue
    fi
    ;;
  esac
  if [ -e "$token" ]; then
    continue
  fi
  if printf '%s\n' "$changed" | grep -qxF "$token"; then
    continue
  fi
  at=$(printf '%s\n' "$prose" | grep -n -F "\`${token}\`" | head -1 | cut -d: -f1 || true)
  if [ -n "$at" ]; then
    at=$((at + fm_close))
  else
    at=0
  fi
  report "$at" path-not-found "\`${token}\` names nothing in the tree or in the diff"
done

if [ "$findings" -gt 0 ]; then
  printf 'TOTAL: %s finding(s) in %s\n' "$findings" "$DRAFT"
  exit 1
fi
