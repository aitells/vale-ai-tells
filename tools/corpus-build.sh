#!/usr/bin/env bash
# corpus-build — assemble the pre-LLM prose corpora a new rule is measured
# against, one paragraph per line, in a cache directory outside the repo.
#
# A rule's fixtures prove it fires. They say nothing about what it wrongly
# flags, and the register that trips a rule (a PEP rejecting an
# alternative, a blog post walking through a mechanism) is invisible from
# inside this repository's own docs. So every candidate token is counted
# against human technical prose written before LLM drafting existed, and
# the count goes in the rule comment.
#
# Two kinds of source. The stdlib comments and docstrings come off this
# machine's Go and Python installs and cover the reference register, terse
# prose next to the thing it describes. The four published sources cover
# explanation and argument, which is the register the padding rules
# target: design rationale (PEPs, Go proposals, Rust RFCs), and the
# explainer voice (the Go blog, Pro Git). Each published source is a
# GitHub archive at a commit pinned before 2022-06-01, so the text
# predates the models, and the pin makes every session count the same
# words.
#
# Output: one paragraph per line with a blank line after it. One line per
# paragraph means a clause-level shape spanning a wrapped line still
# counts, which the earlier line-per-comment extraction undercounted, and
# the blank line means Vale reads each paragraph as its own context. Code
# blocks, headings, tables, directives, and front matter are dropped;
# paragraphs under five words are dropped as fragments.
#
# Usage: bash tools/corpus-build.sh [--force]
#   VALE_AI_TELLS_CORPUS_DIR overrides ~/.cache/vale-ai-tells/corpus.
#
# Then count with ripgrep (PCRE, case-insensitive):
#   rg -icP -- '<pattern>' "$CORPUS_DIR"/*.txt
# or lint through Vale itself, since regexp2 and PCRE differ:
#   vale --config=<ini> --filter='.Name=="ai-tells.<Rule>"' <corpus>.md

set -euo pipefail

CORPUS_DIR="${VALE_AI_TELLS_CORPUS_DIR:-$HOME/.cache/vale-ai-tells/corpus}"
SRC_DIR="$CORPUS_DIR/src"
FORCE=0
[ "${1:-}" = "--force" ] && FORCE=1
mkdir -p "$SRC_DIR"

# --- Reflow filters. Each reads one file on stdin and prints paragraphs.
# A paragraph ends at a blank line or at a line that opens a list item, so
# adjacent items never merge. Paragraphs under five words drop as fragments.

reflow_common='
function flush() {
  if (para != "") {
    gsub(/[ \t]+/, " ", para)
    sub(/^ /, "", para); sub(/ $/, "", para)
    n = split(para, w, " ")
    if (n >= 5) print para "\n"
  }
  para = ""
}
function add(line) {
  sub(/^[ \t]+/, "", line)
  para = para " " line
}
'

# Markdown: fenced code, indented code, headings, tables, HTML, link
# reference definitions, template directives, and YAML front matter drop.
reflow_markdown="$reflow_common"'
NR == 1 && /^---[ \t]*$/ { fm = 1; next }
fm == 1 { if (/^---[ \t]*$/) fm = 0; next }
/^[ \t]*(```|~~~)/ { fence = !fence; next }
fence { next }
/^[ \t]*$/ { flush(); next }
/^(    |\t)/ { next }
/^[ \t]*(#|\||<|\{\{|\[[^]]*\]:)/ { next }
/^[ \t]*([-*+]|[0-9]+\.)[ \t]/ { flush(); add($0); next }
{ add($0) }
END { flush() }
'

# reStructuredText (the PEPs): the header block up to the first blank
# line, underline rules, directives, field lists, and indented blocks
# (literal blocks and block quotes both) drop. A list item keeps its
# continuation lines, which sit two or three spaces in.
reflow_rst="$reflow_common"'
BEGIN { header = 1 }
header == 1 { if (/^[ \t]*$/) header = 0; next }
/^[ \t]*$/ { flush(); in_list = 0; next }
/^[=\-~*^"#`:.+_]{3,}[ \t]*$/ { next }
/^[ \t]*(\.\.|:)/ { next }
/^(  |\t)/ { if (in_list && $0 ~ /^ {2,3}[^ ]/) add($0); next }
/^([-*+]|[0-9]+\.|#\.)[ \t]/ { flush(); in_list = 1; add($0); next }
{ add($0) }
END { flush() }
'

# AsciiDoc (Pro Git): delimited blocks, headings, block titles, attribute
# lines, macros, comments, tables, and indented literals drop; index
# markers and callouts strip inline.
reflow_asciidoc="$reflow_common"'
/^(----|\.\.\.\.|====|\+\+\+\+|____|\*\*\*\*)[ \t]*$/ { block = !block; next }
block { next }
/^[ \t]*$/ { flush(); next }
/^(\[|=|\.[A-Za-z]|image::|include::|\/\/|\||ifdef::|endif::|:)/ { next }
/^(  |\t)/ { next }
{ gsub(/\(\(\([^)]*\)\)\)/, ""); gsub(/<[0-9]+>/, "") }
/^[ \t]*([-*+]|[0-9]+\.)[ \t]/ { flush(); add($0); next }
{ add($0) }
END { flush() }
'

# Go doc comments: every // line with the marker stripped; a non-comment
# line ends the paragraph. Build tags and directives drop.
reflow_go_comments="$reflow_common"'
/^[ \t]*\/\/[ \t]*$/ { flush(); next }
/^[ \t]*\/\/(go:|[ \t]*\+build|[ \t]*export )/ { next }
/^[ \t]*\/\// { line = $0; sub(/^[ \t]*\/\/ ?/, "", line); if (line ~ /^\t/) next; add(line); next }
{ flush() }
END { flush() }
'

# Python: # comment runs and the bodies of triple-quoted strings.
reflow_python="$reflow_common"'
{
  line = $0
  q = gsub(/"""|'"'''"'/, "", line)
  if (q > 0) { in_doc = (in_doc + q) % 2; if (line ~ /^[ \t]*$/) { flush(); next } ; if (q == 2 && in_doc == 0) { add(line); flush(); next } ; add(line); if (!in_doc) flush(); next }
}
in_doc { if ($0 ~ /^[ \t]*$/) flush(); else add($0); next }
/^[ \t]*#[ \t]*$/ { flush(); next }
/^[ \t]*#/ { line = $0; sub(/^[ \t]*#+ ?/, "", line); if (line ~ /^!/) next; add(line); next }
{ flush() }
END { flush() }
'

# --- Sources.

# The archive extracts into a partial directory that becomes the cached
# tree only once the whole pipeline succeeds. A failed download therefore
# leaves nothing a later run could mistake for a cache hit, and the build
# stops here rather than writing an empty corpus.
fetch() {  # name repo sha
  local name="$1" repo="$2" sha="$3"
  local tree="$SRC_DIR/$name-$sha"
  if [ -d "$tree" ]; then echo "  $name: cached $sha"; return; fi
  echo "  $name: fetching $repo@$sha"
  rm -rf "$tree.partial"
  mkdir -p "$tree.partial"
  curl -fsSL "https://github.com/$repo/archive/$sha.tar.gz" | tar -xz -C "$tree.partial" --strip-components=1
  mv "$tree.partial" "$tree"
}

build() {  # name filter find-args...
  local name="$1" filter="$2"; shift 2
  local out="$CORPUS_DIR/$name.txt"
  if [ -s "$out" ] && [ "$FORCE" = 0 ]; then echo "  $name: kept $(grep -c . "$out") paragraphs"; return; fi
  : > "$out"
  find "$@" -print0 | sort -z | while IFS= read -r -d '' f; do
    awk "$filter" "$f" >> "$out"
  done
  echo "  $name: $(grep -c . "$out") paragraphs"
}

echo "corpus: $CORPUS_DIR"

echo "published sources, pinned before 2022-06-01"
fetch peps        python/peps      1dae9310db2d0c5459c9ed0a4f444a902dcf8085
fetch go-proposal golang/proposal  e0113ba8479092562cf9d6d4e0e65d3268c2067a
fetch go-blog     golang/website   ec0d7080e70a7886425b953ab2604510f1d1d55c
fetch rust-rfcs   rust-lang/rfcs   9925276189646646beffbc4f84ca03b037ff7569
fetch progit      progit/progit2   20156cdff88e8d67438c24a0ebaf913e7bbdcd41

echo "extracting"
build peps        "$reflow_rst"      "$SRC_DIR"/peps-*        -maxdepth 1 -name 'pep-*.txt' -o -maxdepth 1 -name 'pep-*.rst'
build go-proposal "$reflow_markdown" "$SRC_DIR"/go-proposal-*/design -name '*.md'
build go-blog     "$reflow_markdown" "$SRC_DIR"/go-blog-*/_content/blog -name '*.md'
build rust-rfcs   "$reflow_markdown" "$SRC_DIR"/rust-rfcs-*/text -name '*.md'
build progit      "$reflow_asciidoc" "$SRC_DIR"/progit-*/book -name '*.asc'

echo "local stdlib sources"
if command -v go >/dev/null 2>&1; then
  build go-stdlib "$reflow_go_comments" "$(go env GOROOT)/src" -name '*.go' -not -name '*_test.go' -not -path '*/testdata/*'
else
  echo "  go-stdlib: skipped, no go on PATH"
fi
if command -v python3 >/dev/null 2>&1; then
  build python-stdlib "$reflow_python" "$(python3 -c 'import sysconfig;print(sysconfig.get_paths()["stdlib"])')" -name '*.py' -not -path '*/test/*' -not -path '*/tests/*' -not -path '*/site-packages/*'
else
  echo "  python-stdlib: skipped, no python3 on PATH"
fi

echo "done: $(cat "$CORPUS_DIR"/*.txt | grep -c .) paragraphs across $(ls "$CORPUS_DIR"/*.txt | wc -l | tr -d ' ') corpora"
