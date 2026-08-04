#!/usr/bin/env -S uv run --script
# /// script
# requires-python = ">=3.14"
# ///
"""session — query a Claude Code transcript without reading it whole.

A transcript is JSONL, one record per line, and a working session runs to
several megabytes. Reading it into context to answer a question about it
costs more than the question is worth and often more than the context
holds. Every subcommand here answers from a streaming pass and prints
line numbers, so the follow-up read is bounded to what those numbers
point at.

The record shapes this relies on, confirmed against Claude Code 2.1.220
transcripts: assistant records carry `message.content` blocks of type
text, thinking, tool_use, and tool_result; user records carry either a
string `message.content` or a block list holding tool_result. A tool
result marks failure with `is_error`, but a shell command that exits
nonzero does not, so `errors` looks for both.

Subcommands print plain text. Nothing here writes to the transcript.

The script metadata above declares no dependencies because there are
none: everything here is standard library. It pins the interpreter
instead, matching the version this project targets. uv fetches that
version when the machine lacks it, so the skill states its own
requirement even in a repository with no Python project.
"""

from __future__ import annotations

import argparse
import datetime as dt
import json
import re
import sys
from collections import Counter, defaultdict
from pathlib import Path
from typing import TYPE_CHECKING

if TYPE_CHECKING:
    from collections.abc import Iterator

# A tool result longer than this gets truncated in summary views. Full
# text stays available through `show`.
SUMMARY_WIDTH = 300

# Two tool calls farther apart than this many records belong to
# different episodes, so `loops` starts a new cluster.
CLUSTER_GAP = 40

# A run reporting at most this many findings is a trickle rather than a
# batch, which is the distinction `lint` reports on.
FEW_FINDINGS = 2


def die(msg: str) -> None:
    print(f"session: {msg}", file=sys.stderr)
    raise SystemExit(1)


def records(path: str) -> Iterator[tuple[int, dict]]:
    """Yield (lineno, parsed) for each record, skipping unparseable lines.

    A truncated final line is normal in a transcript still being written,
    so a parse failure is reported once and does not stop the pass.
    """
    bad = 0
    with Path(path).open(encoding="utf-8", errors="replace") as fh:
        for lineno, raw in enumerate(fh, 1):
            line = raw.strip()
            if not line:
                continue
            try:
                yield lineno, json.loads(line)
            except ValueError, TypeError:
                bad += 1
    if bad:
        print(f"(skipped {bad} unparseable line(s))", file=sys.stderr)


def blocks(rec: dict) -> Iterator[tuple[str, str]]:
    """Yield (kind, text) for every content block in a record.

    Kinds are TEXT, THINK, USE:<tool>, RES, and STR. Tool inputs and
    results collapse to text so one regex can search across all of them.
    """
    message = rec.get("message") or {}
    content = message.get("content")
    if isinstance(content, str):
        yield "STR", content
        return
    if not isinstance(content, list):
        return
    for blk in content:
        kind = blk.get("type")
        if kind == "text":
            yield "TEXT", blk.get("text", "")
        elif kind == "thinking":
            yield "THINK", blk.get("thinking", "")
        elif kind == "tool_use":
            name = blk.get("name", "?")
            inp = blk.get("input") or {}
            if name == "Bash":
                body = str(inp.get("command", ""))
            elif name in ("Edit", "Write", "Read"):
                body = str(inp.get("file_path", ""))
            else:
                body = json.dumps(inp)
            yield f"USE:{name}", body
        elif kind == "tool_result":
            yield "RES", result_text(blk)


def result_text(blk: dict) -> str:
    content = blk.get("content")
    if isinstance(content, list):
        return " ".join(
            part.get("text", "") for part in content if isinstance(part, dict)
        )
    return str(content)


def tool_calls(rec: dict) -> Iterator[tuple[str, dict]]:
    """Yield (name, input) for each tool_use block in a record."""
    message = rec.get("message") or {}
    content = message.get("content")
    if not isinstance(content, list):
        return
    for blk in content:
        if blk.get("type") == "tool_use":
            yield blk.get("name", "?"), (blk.get("input") or {})


def flat(text: str, width: int = SUMMARY_WIDTH) -> str:
    return " ".join(text.split())[:width]


# --- locate ---------------------------------------------------------------


def project_dirs() -> list[Path]:
    root = Path("~/.claude/projects").expanduser()
    if not root.is_dir():
        return []
    return sorted(p for p in root.iterdir() if p.is_dir())


def cmd_locate(args: argparse.Namespace) -> None:
    """Find transcripts, optionally filtering by a content fingerprint.

    Path guessing is the mistake this exists to avoid. A session run inside
    a git worktree writes its transcript under the *main* repository's
    project directory; the worktree's own directory may exist and hold
    no JSONL at all. Searching by content settles which file is which.
    """
    hits = []
    for pdir in project_dirs():
        if args.project and args.project not in pdir.name:
            continue
        for path in sorted(pdir.iterdir()):
            if path.suffix != ".jsonl":
                continue
            size = path.stat().st_size
            if args.contains:
                with path.open(encoding="utf-8", errors="replace") as fh:
                    found = sum(1 for line in fh if args.contains in line)
                if not found:
                    continue
                hits.append((path, size, found))
            else:
                hits.append((path, size, None))

    if not hits:
        print("no transcript matched")
        if args.contains:
            print("(a zero-hit search proves nothing until you confirm the")
            print(" fingerprint appears in some transcript at all)")
        return

    hits.sort(key=lambda h: h[0].stat().st_mtime, reverse=True)
    for path, size, found in hits:
        mark = f"  matches={found}" if found is not None else ""
        print(f"{size / 1e6:7.1f} MB  {path}{mark}")


# --- index ----------------------------------------------------------------


def cmd_index(args: argparse.Namespace) -> None:
    """Summarize the whole transcript in one pass.

    This is the first command to run. It answers how big the session
    was, which tools carried it, and where the failures cluster, without
    putting any transcript prose into context.
    """
    kinds = Counter()
    tools = Counter()
    errors = []
    sidechain = 0
    total = 0

    for lineno, rec in records(args.path):
        total += 1
        kinds[rec.get("type", "?")] += 1
        if rec.get("isSidechain"):
            sidechain += 1
        for name, _ in tool_calls(rec):
            tools[name] += 1
        for kind, text in blocks(rec):
            if kind == "RES" and is_failure(rec, text):
                errors.append(lineno)

    print(f"records:        {total}")
    print(f"sidechain:      {sidechain}")
    print(f"record types:   {dict(kinds.most_common())}")
    print()
    print("tool calls:")
    for name, count in tools.most_common():
        print(f"  {count:5d}  {name}")
    print()
    print(f"failing results: {len(errors)}")
    if errors:
        print(f"  lines: {errors[:60]}")
    print()
    print("next: `errors` for what failed, `loops` for what repeated")


def is_failure(rec: dict, text: str) -> bool:
    """Decide whether a tool result represents a failure.

    `is_error` alone undercounts badly. A Bash call that exits nonzero
    comes back as an ordinary result, and so does a linter reporting
    findings, so those get matched on their text.
    """
    message = rec.get("message") or {}
    content = message.get("content")
    if isinstance(content, list):
        for blk in content:
            if blk.get("type") == "tool_result" and blk.get("is_error"):
                return True
    return bool(
        re.search(
            r"Exit code [1-9]|exit=[1-9]|command not found|"
            r"No such file or directory|hook error|has been denied|"
            r"illegal option|invalid option|Permission denied",
            text,
        )
    )


# --- errors ---------------------------------------------------------------


def cmd_errors(args: argparse.Namespace) -> None:
    """List every failing result with its line number and first line."""
    shown = 0
    for lineno, rec in records(args.path):
        for kind, text in blocks(rec):
            if kind != "RES" or not is_failure(rec, text):
                continue
            label = classify(text)
            print(f"L{lineno:<6} [{label}] {flat(text, args.width)}")
            shown += 1
    print(f"\n{shown} failing result(s)")


def classify(text: str) -> str:
    if "hook error" in text:
        return "hook-block"
    if "has been denied" in text:
        return "permission"
    if re.search(r"command not found|illegal option|invalid option", text):
        return "environment"
    if re.search(r"\[error\] ", text):
        return "lint"
    return "nonzero"


# --- grep -----------------------------------------------------------------


def cmd_grep(args: argparse.Namespace) -> None:
    """Show regex matches with surrounding context and line numbers.

    Searching the raw JSONL with the shell finds the record but hands
    back an escaped one-line blob. This searches the decoded blocks
    instead, so the context that prints is the text as the model saw it.
    """
    pattern = re.compile(args.pattern, re.IGNORECASE if args.ignore_case else 0)
    lo, hi = args.range
    count = 0
    for lineno, rec in records(args.path):
        if lineno < lo or lineno > hi:
            continue
        for kind, text in blocks(rec):
            if args.kind and not kind.startswith(args.kind):
                continue
            for match in pattern.finditer(text):
                start = max(0, match.start() - args.context)
                end = match.end() + args.context
                print(f"--- L{lineno} [{kind}] ---")
                print(flat(text[start:end], args.context * 2 + 200))
                count += 1
                if args.first:
                    break
    print(f"\n{count} match(es)")


# --- show -----------------------------------------------------------------


def cmd_show(args: argparse.Namespace) -> None:
    """Print whole records, decoded, for a set of line numbers."""
    wanted = set()
    for raw in args.lines.split(","):
        part = raw.strip()
        if "-" in part:
            first, last = part.split("-", 1)
            wanted.update(range(int(first), int(last) + 1))
        elif part:
            wanted.add(int(part))

    for lineno, rec in records(args.path):
        if lineno not in wanted:
            continue
        print(f"\n===== L{lineno} [{rec.get('type')}] =====")
        for kind, text in blocks(rec):
            print(f"[{kind}]")
            print(text[: args.width])


# --- loops ----------------------------------------------------------------


def signature(name: str, inp: dict) -> str:
    """Reduce a tool call to what makes two calls "the same attempt".

    For Bash that means the tasks and commands invoked rather than the
    arguments, so an edit-then-relint cycle collapses to one signature
    across its rounds.
    """
    if name != "Bash":
        return f"{name}:{inp.get('file_path', '')}"
    cmd = str(inp.get("command", ""))
    # Task names carry an optional namespace, as in repotools:lint-toml,
    # so the colon belongs in the class.
    tasks = re.findall(r"\bmise\s+run\s+([a-z0-9:-]+)", cmd)
    if tasks:
        return "mise run " + ",".join(sorted(set(tasks)))
    heads = re.findall(r"(?:^|\n|&&|\|\||;)\s*([a-z][a-z0-9_-]*)", cmd)
    keep = [h for h in heads if h not in ("cd", "echo", "printf", "set", "export")]
    return "sh:" + ",".join(sorted(set(keep))[:3])


def cmd_loops(args: argparse.Namespace) -> None:
    """Cluster repeated equivalent tool calls into retry loops.

    A loop is the unit of waste worth reporting: not one failure, but
    the same attempt made repeatedly with edits in between. Clusters are
    ranked by round count, which approximates the round trips wasted.
    """
    calls = []
    for lineno, rec in records(args.path):
        for name, inp in tool_calls(rec):
            calls.append((lineno, signature(name, inp)))

    groups = defaultdict(list)
    for lineno, sig in calls:
        groups[sig].append(lineno)

    clusters = []
    for sig, linenos in groups.items():
        run = [linenos[0]]
        for lineno in linenos[1:]:
            if lineno - run[-1] <= CLUSTER_GAP:
                run.append(lineno)
            else:
                clusters.append((sig, run))
                run = [lineno]
        clusters.append((sig, run))

    clusters = [c for c in clusters if len(c[1]) >= args.min_rounds]
    clusters.sort(key=lambda c: len(c[1]), reverse=True)

    total = 0
    for sig, run in clusters:
        span = f"L{run[0]}-{run[-1]}"
        print(f"{len(run):4d} rounds  {span:<16} {sig}")
        total += len(run) - 1
    print(f"\n{len(clusters)} loop(s), ~{total} repeat round trip(s) beyond first try")


# --- lint -----------------------------------------------------------------


def cmd_lint(args: argparse.Namespace) -> None:
    """Profile linter findings: which rules fired, and how they arrived.

    The distribution matters more than the total. Many failing runs each
    reporting one or two findings needs a different fix than a few runs
    reporting many at once.
    """
    rules = Counter()
    per_run = []
    for _, rec in records(args.path):
        for kind, text in blocks(rec):
            if kind != "RES":
                continue
            found = re.findall(r"\[error\] ([A-Za-z0-9_.-]+) match=", text)
            if not found and "[error]" not in text:
                continue
            rules.update(found)
            per_run.append(len(found))

    failing = [n for n in per_run if n]
    print(f"runs reporting findings: {len(failing)}")
    print(f"total findings:          {sum(failing)}")
    if failing:
        few = sum(1 for n in failing if n <= FEW_FINDINGS)
        print(f"runs reporting 1-2:      {few} ({100 * few // len(failing)}%)")
        print(f"histogram:               {dict(sorted(Counter(failing).items()))}")
    print()
    print("rules by frequency:")
    for rule, count in rules.most_common(args.top):
        print(f"  {count:5d}  {rule}")


# --- meta ----------------------------------------------------------------


def cmd_meta(args: argparse.Namespace) -> None:
    """Print shell-consumable session metadata for new-retro.sh.

    The date comes from the session's own last stamped record rather than
    from whenever the scaffolding runs, so re-scaffolding an old
    transcript uses the directory it already had.
    """
    path = Path(args.path)
    stamp = ""
    total = 0
    for _, rec in records(args.path):
        total += 1
        if rec.get("timestamp"):
            stamp = rec["timestamp"]

    when = None
    if stamp:
        try:
            when = dt.datetime.fromisoformat(stamp).astimezone()
        except ValueError:
            when = None
    if when is None:
        when = dt.datetime.fromtimestamp(path.stat().st_mtime, tz=dt.UTC).astimezone()

    name = path.name.removesuffix(".jsonl")

    print(f"SESSION_ID={name}")
    print(f"SESSION_DATE={when.strftime('%Y%m%d')}")
    print(f"RECORDS={total}")
    print(f"SIZE_MB={path.stat().st_size / 1e6:.1f}")


# --- main -----------------------------------------------------------------


def main() -> None:
    parser = argparse.ArgumentParser(
        prog="session", description="Query a Claude Code transcript."
    )
    sub = parser.add_subparsers(dest="cmd", required=True)

    loc = sub.add_parser("locate", help="find transcripts by fingerprint")
    loc.add_argument("--contains", help="string that must appear in the file")
    loc.add_argument("--project", help="substring of the project directory name")
    loc.set_defaults(func=cmd_locate)

    for name, func, helptext in (
        ("index", cmd_index, "one-pass summary: size, tools, failures"),
        ("errors", cmd_errors, "every failing result with line numbers"),
        ("loops", cmd_loops, "clusters of repeated equivalent calls"),
        ("lint", cmd_lint, "linter rule frequency and arrival pattern"),
        ("meta", cmd_meta, "session id, date, size (for new-retro.sh)"),
    ):
        spec = sub.add_parser(name, help=helptext)
        spec.add_argument("path")
        spec.set_defaults(func=func)

    for spec in (sub.choices["errors"],):
        spec.add_argument("--width", type=int, default=SUMMARY_WIDTH)
    sub.choices["loops"].add_argument("--min-rounds", type=int, default=3)
    sub.choices["lint"].add_argument("--top", type=int, default=25)

    grep = sub.add_parser("grep", help="regex over decoded content blocks")
    grep.add_argument("path")
    grep.add_argument("pattern")
    grep.add_argument("--context", type=int, default=250)
    grep.add_argument("--kind", help="restrict to TEXT, THINK, USE:Bash, RES")
    grep.add_argument("--ignore-case", action="store_true")
    grep.add_argument("--first", action="store_true", help="one match per block")
    grep.add_argument(
        "--range",
        type=int,
        nargs=2,
        default=(0, 10**9),
        metavar=("LO", "HI"),
        help="restrict to a line range",
    )
    grep.set_defaults(func=cmd_grep)

    show = sub.add_parser("show", help="print whole records by line number")
    show.add_argument("path")
    show.add_argument("lines", help="comma-separated, ranges allowed: 12,40-45")
    show.add_argument("--width", type=int, default=2000)
    show.set_defaults(func=cmd_show)

    args = parser.parse_args()
    if getattr(args, "path", None) and not Path(args.path).is_file():
        die(f"no such transcript: {args.path}")
    args.func(args)


if __name__ == "__main__":
    main()
