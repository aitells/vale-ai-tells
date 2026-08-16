#!/usr/bin/env bash
# fix-prose-replacements — apply every vale finding that already carries
# its own correction, and leave the rest alone.
#
# Some of a typical run needs no judgment at all. Google.WordList wants
# "turn off" for "disable", Google.Latin wants "for example" for "e.g.".
# The ai-tells-agent template already prints the replacement
# as replace_with= on the finding line, because the rule's own action
# carries it. Reading those lines into a model and having it retype the
# answer costs tokens to reproduce a lookup.
#
# The share is smaller here than in the repository this was ported from.
# The Google and proselint rules carry a replacement at warning level
# or above, and ai-tells.HouseStyle carries its house -> project swap.
# The other ai-tells rules describe what is wrong rather than
# substitute for it, on purpose. A pass over this repository's own docs
# at the time of writing turned up 3 replaceable findings out of 12.
# Applying them still leaves the model only the findings that need a
# decision, which is the point.
#
# Safety comes from refusing to guess. Vale gives a line and a column
# span, and this checks that the span holds the exact text the finding
# quoted before touching it. A span that holds anything else means the
# file moved under the report, so that finding is skipped and named
# rather than applied. Findings on one line apply right to left, so an
# earlier replacement never shifts a later span.
#
# Rules that rewrite meaning stay out by construction: a finding with no
# replace_with is never touched, and that covers every distributional
# rule and every judgment call, which is most of what ai-tells flags.
#
# Prints one line per applied change and one per skip. Silence means
# nothing carried a replacement.
#
# Usage: fix-prose-replacements.sh <file>
set -uo pipefail

# --- environment hardening -------------------------------------------
# The agent reads this output, so the operator's preferences must not
# change its shape. PYTHONUTF8 is the companion to LC_ALL: without it
# python would read these files as ASCII under LC_ALL=C and raise on the
# first non-ASCII character.
export LC_ALL=C
export PYTHONUTF8=1
unset CDPATH GREP_OPTIONS
IFS=$(printf ' \t\n')

root=$(git rev-parse --show-toplevel)
cd "$root" || exit 1

file=${1:-}
[ -n "$file" ] || {
  printf 'usage: fix-prose-replacements.sh <file>\n' >&2
  exit 2
}
[ -f "$file" ] || {
  printf '%s:1 [error] missing-file  no such file\n' "$file"
  exit 1
}

findings=$(vale --output=ai-tells-agent.tmpl "$file" 2>/dev/null || true)
[ -n "$findings" ] || exit 0

printf '%s\n' "$findings" | python3 -c '
import json, re, sys

path = sys.argv[1]

# The template prints match and replace_with as Go %q strings. Those
# overlap JSON string syntax for the escapes prose actually produces,
# so json.loads decodes them without running anything. A form it cannot
# read gets reported and skipped rather than guessed at.
LINE = re.compile(
    r"^(?P<line>\d+):(?P<start>\d+)-(?P<end>\d+) \[\w+\] (?P<rule>\S+) "
    r"match=(?P<match>\"(?:[^\"\\\\]|\\\\.)*\")"
    r"(?: replace_with=(?P<repl>\"(?:[^\"\\\\]|\\\\.)*\"))?"
)

# Google.Contractions pairs a pronoun with a form of "be" wherever the
# two sit next to each other, including across a clause boundary where
# the pronoun is really the object of the preceding preposition. Vale
# offers the contraction anyway, and taking it breaks the sentence:
# "a verdict from that is narrower" becomes "from that\x27s narrower",
# and "the cost of a fix for it is another round" becomes "for it\x27s
# another round".
#
# So a pronoun contraction whose preceding word is a preposition gets
# reported rather than applied. A model reading the sentence settles it
# in one look, which is the whole division of labor here.
#
# Google.Contractions ships at suggestion level and .vale.ini sets
# MinAlertLevel = warning, so it stays quiet in this repository as
# configured today. The guard keys on the matched text rather than on
# the rule name, so it also covers a lowered threshold and any future
# substitution rule that offers the same shape.
OBJECT_PRONOUN = re.compile(r"^(it|that|there|this|these|those)\s+(is|are|was|were)$", re.I)
PREPOSITION = {
    "about", "after", "against", "at", "before", "by", "for", "from",
    "in", "into", "of", "on", "over", "than", "through", "to", "under",
    "upon", "with", "without",
}

edits = []
for raw in sys.stdin:
    m = LINE.match(raw)
    if not m or not m.group("repl"):
        continue
    try:
        match = json.loads(m.group("match"))
        repl = json.loads(m.group("repl"))
    except ValueError:
        lineno = m.group("line")
        print(f"{path}:{lineno} [error] unparsable-quoting  {raw.strip()}")
        continue
    edits.append((
        int(m.group("line")), int(m.group("start")), int(m.group("end")),
        m.group("rule"), match, repl,
    ))

if not edits:
    sys.exit(0)

with open(path, encoding="utf-8") as fh:
    lines = fh.read().split("\n")

applied = skipped = 0
# Right to left within a line, so an applied edit never moves a span
# that has not been applied yet.
for ln, start, end, rule, match, repl in sorted(edits, key=lambda e: (e[0], -e[1])):
    if ln > len(lines):
        continue
    text = lines[ln - 1]
    found = text[start - 1:end]
    if OBJECT_PRONOUN.match(match):
        prior = text[:start - 1].rstrip().split()
        if prior and prior[-1].strip("(,;:").lower() in PREPOSITION:
            print(f"{path}:{ln} [error] context-sensitive  {rule} would write {repl!r} after {prior[-1]!r}, which breaks the clause; reword it by hand")
            skipped += 1
            continue
    if found != match:
        print(f"{path}:{ln} [error] span-mismatch  {rule} quoted {match!r} but the span holds {found!r}; skipped")
        skipped += 1
        continue
    lines[ln - 1] = text[:start - 1] + repl + text[end:]
    print(f"{path}:{ln} [fixed] {rule}  {match!r} -> {repl!r}")
    applied += 1

if applied:
    with open(path, "w", encoding="utf-8") as fh:
        fh.write("\n".join(lines))

print(f"TOTAL: {applied} applied, {skipped} skipped")
sys.exit(1 if skipped else 0)
' "$file"
