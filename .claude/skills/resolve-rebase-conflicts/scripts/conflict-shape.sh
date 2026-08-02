#!/usr/bin/env bash
# conflict-shape — decide what shape a single conflict has, from the
# three complete versions of the file rather than from the markers.
#
# Both the classifier and the union resolver need the same judgement, so
# it lives in one place and answers to one set of conditions. Splitting
# it would let the two drift, and the drift that matters is the one
# where a path is classified mechanical and then resolved by a rule that
# no longer agrees.
#
# Working from the stages instead of the marker regions is deliberate. A
# marker region shows the lines that disagree; it cannot show a line one
# side deleted somewhere else in the file, and that deletion is exactly
# what makes a union the wrong answer. Sortedness is a property of the
# whole file too. Neither question is answerable from a region.
#
# Usage: conflict-shape.sh <mode> <path> <ancestor> <base-side> <replayed-side>
#        mode `classify` prints a classification block on stdout.
#        mode `union` prints the resolved file content on stdout, and
#        exits 3 without printing when the union is not provably safe.
# Env:   DECLARED carries the path's rebase-resolve attribute value.
set -euo pipefail

# --- environment hardening -------------------------------------------
# LC_ALL pins the collation the sortedness test judges against. These
# files are written and sorted under the C locale, and judging them
# under a UTF-8 one would call a sorted file unsorted. The comparison
# below happens on bytes in python for the same reason, so this is
# belt and braces, but the byte comparison is the one that binds.
export LC_ALL=C
export PYTHONUTF8=1
unset CDPATH GREP_OPTIONS
IFS=$(printf ' \t\n')

mode=${1:?usage: conflict-shape.sh <mode> <path> <ancestor> <base-side> <replayed-side>}
shift

MODE="$mode" DECLARED="${DECLARED:-}" python3 - "$@" <<'PY'
import difflib
import os
import pathlib
import sys

mode = os.environ["MODE"]
declared = os.environ.get("DECLARED", "").strip()
path, ancestor_f, base_f, replayed_f = sys.argv[1:5]

ANCESTOR = "ancestor"
BASE = "base-side"
REPLAYED = "replayed-side"


def read(name):
    """Return (lines, note) for a stage file, or (None, why) when unusable."""
    p = pathlib.Path(name)
    if not p.exists() or p.stat().st_size == 0:
        return None, "absent"
    data = p.read_bytes()
    if b"\0" in data:
        return None, "binary"
    trailing = data.endswith(b"\n")
    lines = data.split(b"\n")
    if trailing:
        lines.pop()
    return lines, ("" if trailing else "no trailing newline")


anc, anc_note = read(ancestor_f)
base, base_note = read(base_f)
rep, rep_note = read(replayed_f)


def sorted_unique(lines):
    return lines == sorted(lines) and len(set(lines)) == len(lines)


def union_verdict():
    """Why a sorted union is or is not provably safe here."""
    if declared == "manual":
        return None, "the path is declared rebase-resolve=manual"
    for name, lines, note in ((ANCESTOR, anc, anc_note), (BASE, base, base_note), (REPLAYED, rep, rep_note)):
        if lines is None:
            return None, f"the {name} version is {note}"
    for name, lines in ((ANCESTOR, anc), (BASE, base), (REPLAYED, rep)):
        if not sorted_unique(lines):
            return None, f"the {name} version is not sorted and unique under the C collation"
    lost_base = set(anc) - set(base)
    lost_rep = set(anc) - set(rep)
    if lost_base or lost_rep:
        gone = sorted(lost_base | lost_rep)[:3]
        shown = ", ".join(line.decode("utf-8", "replace") for line in gone)
        return None, f"a side removed a line the ancestor had ({shown}), so a union would put it back"
    return sorted(set(base) | set(rep)), ""


def token_union():
    """A single line both sides extended with extra whitespace-separated tokens."""
    if anc is None or base is None or rep is None:
        return []

    def replacements(side):
        out = {}
        for tag, i1, i2, j1, j2 in difflib.SequenceMatcher(None, anc, side).get_opcodes():
            if tag == "replace" and i2 - i1 == 1 and j2 - j1 == 1:
                out[i1] = side[j1]
        return out

    r_base, r_rep = replacements(base), replacements(rep)
    found = []
    for i in sorted(set(r_base) & set(r_rep)):
        a, b, c = anc[i], r_base[i], r_rep[i]
        ta, tb, tc = a.split(), b.split(), c.split()
        if not ta or set(ta) - set(tb) or set(ta) - set(tc) or tb == tc:
            continue
        indent = a[: len(a) - len(a.lstrip())]
        merged = list(ta)
        for token in tb + tc:
            if token not in merged:
                merged.append(token)
        found.append((i, a, b, c, indent + b" ".join(merged)))
    return found


def show(raw):
    return raw.decode("utf-8", "replace")


result, why = union_verdict()

if mode == "union":
    if result is None:
        sys.stderr.write(f"conflict-shape: {path} is not a provable sorted union: {why}\n")
        sys.exit(3)
    sys.stdout.write("\n".join(show(line) for line in result) + "\n")
    sys.exit(0)

if result is not None:
    added_base = sorted(set(base) - set(anc))
    added_rep = sorted(set(rep) - set(anc))
    print("class: sorted-union  (mechanical, resolve without asking)")
    print("  evidence: all three versions sorted and unique under the C collation,")
    print("            and neither side removed a line the ancestor had")
    print(f"  ancestor {len(anc)} lines; {BASE} added {len(added_base)}; {REPLAYED} added {len(added_rep)}")
    both = sorted(set(added_base) & set(added_rep))
    if both:
        print(f"  {len(both)} line(s) added by both sides, which the union keeps once")
    print(f"  result: {len(result)} lines")
    print("  resolve: bash .claude/skills/resolve-rebase-conflicts/scripts/resolve-union.sh " + path)
    if declared == "union":
        print("  declared: rebase-resolve=union, and the evidence agrees")
    sys.exit(0)

if declared == "union":
    print(f"NOTE: declared rebase-resolve=union, but {why}.")
    print("      The declaration is now wrong, or the file stopped being an")
    print("      append-only sorted list. Say so rather than forcing the union.")

pairs = token_union()
if pairs:
    print("class: token-union  (proposal below; the ordering needs your read)")
    print("  Both sides extended the same line with extra tokens rather than")
    print("  rewriting it, so the union of the additions is the content. Where")
    print("  those tokens go in the line is a judgement this cannot make.")
    for i, a, b, c, proposal in pairs:
        print(f"\n  line {i + 1}")
        print(f"    {ANCESTOR}:      {show(a)}")
        print(f"    {BASE}:      {show(b)}     added: {' '.join(show(t) for t in b.split() if t not in a.split())}")
        print(f"    {REPLAYED}:  {show(c)}     added: {' '.join(show(t) for t in c.split() if t not in a.split())}")
        print(f"    proposal:       {show(proposal)}")
    print("\n  Confirm the ordering with the operator, apply it by editing the file,")
    print("  then stage the path.")
    sys.exit(0)

print("class: content  (needs a reader)")
print(f"  not a sorted union: {why}")
for name, lines, note in ((ANCESTOR, anc, anc_note), (BASE, base, base_note), (REPLAYED, rep, rep_note)):
    if lines is None:
        print(f"  {name}: {note}")
    else:
        extra = f", {note}" if note else ""
        print(f"  {name}: {len(lines)} lines{extra}")
print("  Read what each side was trying to do, below, before touching the file.")
PY
