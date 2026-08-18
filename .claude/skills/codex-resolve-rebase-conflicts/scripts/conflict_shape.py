#!/usr/bin/env -S uv run --script
# /// script
# requires-python = ">=3.14"
# dependencies = []
# ///
# pylint: disable=duplicate-code
# This deterministic classifier deploys inside a standalone harness package.
# Keeping it byte-equivalent across harnesses is the behavior being protected.
"""Decide what shape a single conflict has.

Works from the three complete versions of the file rather than from the
markers.

Both the classifier and the union resolver need the same judgement, so it
lives in one place and answers to one set of conditions. Splitting it would
let the two drift, and the drift that matters is the one where a path is
classified mechanical and then resolved by a rule that no longer agrees.

Working from the stages instead of the marker regions is deliberate. A
marker region shows the lines that disagree; it cannot show a line one side
deleted somewhere else in the file, and that deletion is exactly what makes
a union the wrong answer. Sortedness is a property of the whole file too.
Neither question is answerable from a region.

Usage:
    conflict_shape.py <mode> <path> <ancestor> <base-side> <replayed-side>

    Mode `classify` prints a classification block on stdout.
    Mode `union` prints the resolved file content on stdout, and exits 3
    without printing when the union is not provably safe.

Env:
    DECLARED carries the path's rebase-resolve attribute value.

Exit:
    0  the mode completed and printed its answer
    2  the invocation was wrong
    3  `union` mode refused, because the union is not provable here

Any other status is a defect in this script rather than a verdict about the
file, and callers must tell the two apart. Exit 3 is the only refusal.

The shell wrapper this replaced exported LC_ALL=C to pin the collation the
sortedness test judges against. Nothing here needs it: every comparison
below is on `bytes`, which orders by byte value under every locale. That was
true of the wrapper too, which is why it could go.
"""

import difflib
import os
import pathlib
import sys

# A stage is the file's lines, or None with a note saying why it is unusable.
type Stage = tuple[list[bytes] | None, str]
type Stages = tuple[Stage, Stage, Stage]
type TokenPair = tuple[int, bytes, bytes, bytes, bytes]

# The three versions once every one of them has been read. union_verdict only
# returns a result when this holds, but the two facts are separate as far as
# the type checker is concerned, so `present` carries the narrowing.
type Present = tuple[list[bytes], list[bytes], list[bytes]]

ANCESTOR = "ancestor"
BASE = "base-side"
REPLAYED = "replayed-side"
NAMES = (ANCESTOR, BASE, REPLAYED)

USAGE = "usage: conflict_shape.py <mode> <path> <ancestor> <base-side> <replayed-side>"

# A refusal, as distinct from a crash. Callers branch on this exact status,
# so it must not collide with the 1 an unhandled exception exits with.
REFUSED = 3
MISUSE = 2

# argv is the mode plus the path plus the three stage files.
ARGC = 5

MODES = ("classify", "union")


def read(name: str) -> Stage:
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


def sorted_unique(lines: list[bytes]) -> bool:
    return lines == sorted(lines) and len(set(lines)) == len(lines)


def present(stages: Stages) -> tuple[Present | None, str]:
    """The three versions when all three read, or None and the reason why not."""
    anc, base, rep = (lines for lines, _ in stages)
    if anc is None or base is None or rep is None:
        return None, next(
            f"the {name} version is {note}"
            for name, (lines, note) in zip(NAMES, stages, strict=True)
            if lines is None
        )
    return (anc, base, rep), ""


def union_verdict(declared: str, stages: Stages) -> tuple[list[bytes] | None, str]:
    """Why a sorted union is or is not provably safe here."""
    if declared == "manual":
        return None, "the path is declared rebase-resolve=manual"
    versions, why = present(stages)
    if versions is None:
        return None, why
    anc, base, rep = versions
    for name, lines in zip(NAMES, versions, strict=True):
        if not sorted_unique(lines):
            return (
                None,
                f"the {name} version is not sorted and unique under the C collation",
            )
    lost_base = set(anc) - set(base)
    lost_rep = set(anc) - set(rep)
    if lost_base or lost_rep:
        gone = sorted(lost_base | lost_rep)[:3]
        shown = ", ".join(line.decode("utf-8", "replace") for line in gone)
        why = (
            f"a side removed a line the ancestor had ({shown}), "
            f"so a union would put it back"
        )
        return None, why
    return sorted(set(base) | set(rep)), ""


def token_union(
    anc: list[bytes] | None, base: list[bytes] | None, rep: list[bytes] | None
) -> list[TokenPair]:
    """A single line both sides extended with extra whitespace-separated tokens."""
    if anc is None or base is None or rep is None:
        return []

    def replacements(side: list[bytes]) -> dict[int, bytes]:
        out = {}
        matcher = difflib.SequenceMatcher(None, anc, side)
        for tag, i1, i2, j1, j2 in matcher.get_opcodes():
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


def show(raw: bytes) -> str:
    return raw.decode("utf-8", "replace")


def added(side: bytes, anc: bytes) -> str:
    return " ".join(show(t) for t in side.split() if t not in anc.split())


def print_sorted_union(
    declared: str, path: str, result: list[bytes], versions: Present
) -> None:
    anc, base, rep = versions
    added_base = sorted(set(base) - set(anc))
    added_rep = sorted(set(rep) - set(anc))
    print("class: sorted-union  (mechanical, resolve without asking)")
    print("  evidence: all three versions sorted and unique under the C collation,")
    print("            and neither side removed a line the ancestor had")
    print(
        f"  ancestor {len(anc)} lines; {BASE} added {len(added_base)}; "
        f"{REPLAYED} added {len(added_rep)}"
    )
    both = sorted(set(added_base) & set(added_rep))
    if both:
        print(f"  {len(both)} line(s) added by both sides, which the union keeps once")
    print(f"  result: {len(result)} lines")
    print(
        "  resolve: bash .agents/skills/codex-resolve-rebase-conflicts/scripts/"
        "resolve-union.sh " + path
    )
    if declared == "union":
        print("  declared: rebase-resolve=union, and the evidence agrees")


def print_token_union(pairs: list[TokenPair]) -> None:
    print("class: token-union  (proposal below; the ordering needs your read)")
    print("  Both sides extended the same line with extra tokens rather than")
    print("  rewriting it, so the union of the additions is the content. Where")
    print("  those tokens go in the line is a judgement this cannot make.")
    for i, a, b, c, proposal in pairs:
        print(f"\n  line {i + 1}")
        print(f"    {ANCESTOR}:      {show(a)}")
        print(f"    {BASE}:      {show(b)}     added: {added(b, a)}")
        print(f"    {REPLAYED}:  {show(c)}     added: {added(c, a)}")
        print(f"    proposal:       {show(proposal)}")
    print("\n  Confirm the ordering with the operator, apply it by editing the file,")
    print("  then stage the path.")


def print_content(why: str, stages: Stages) -> None:
    (anc, anc_note), (base, base_note), (rep, rep_note) = stages
    print("class: content  (needs a reader)")
    print(f"  not a sorted union: {why}")
    for name, lines, note in (
        (ANCESTOR, anc, anc_note),
        (BASE, base, base_note),
        (REPLAYED, rep, rep_note),
    ):
        if lines is None:
            print(f"  {name}: {note}")
        else:
            extra = f", {note}" if note else ""
            print(f"  {name}: {len(lines)} lines{extra}")
    print("  Read what each side was trying to do, below, before touching the file.")


def main(argv: list[str]) -> int:
    if len(argv) != ARGC or argv[0] not in MODES:
        sys.stderr.write(USAGE + "\n")
        return MISUSE
    mode, path, ancestor_f, base_f, replayed_f = argv

    declared = os.environ.get("DECLARED", "").strip()
    stages = (read(ancestor_f), read(base_f), read(replayed_f))
    result, why = union_verdict(declared, stages)

    if mode == "union":
        if result is None:
            sys.stderr.write(
                f"conflict-shape: {path} is not a provable sorted union: {why}\n"
            )
            return REFUSED
        sys.stdout.write("\n".join(show(line) for line in result) + "\n")
        return 0

    versions, _ = present(stages)
    # The second condition is narrowing rather than a second question: a
    # result exists only when all three versions read.
    if result is not None and versions is not None:
        print_sorted_union(declared, path, result, versions)
        return 0

    if declared == "union":
        print(f"NOTE: declared rebase-resolve=union, but {why}.")
        print("      The declaration is now wrong, or the file stopped being an")
        print("      append-only sorted list. Say so rather than forcing the union.")

    anc, base, rep = (lines for lines, _ in stages)
    pairs = token_union(anc, base, rep)
    if pairs:
        print_token_union(pairs)
        return 0

    print_content(why, stages)
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
