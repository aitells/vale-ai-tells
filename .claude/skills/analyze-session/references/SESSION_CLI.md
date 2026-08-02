# `session.py`

The query tool this skill uses. It reads a transcript line by line and prints totals with line numbers, so nothing needs the whole file in context.

It has a uv script shebang and declares which Python version it needs, so it runs directly:

```text
.claude/skills/analyze-session/scripts/session.py <subcommand> <transcript> [options]
```

The preflight already runs `index`, `errors`, `loops` and `lint`, and leaves the full output in the retro's `artifacts/`. Run the tool directly when a report needs more detail than the preflight printed, or when the reports point at something worth searching for.

## `locate`

```text
session.py locate --contains 'some-distinctive-string' [--project SUBSTRING]
```

Finds transcripts by content instead of by a guessed directory name. Output is size, path, and match count, newest first.

Worktrees complicate this. A session running inside a git worktree writes its transcript under the main repository's project directory, and the worktree's own directory may exist while holding no `.jsonl` at all, so guessing that path finds an empty directory that looks identical to a missing transcript.

A search with no hits proves nothing on its own. Confirm the same string matches some other transcript before concluding this session is absent.

## `index`

One pass over everything. Prints the record count, how many records are sidechain, the record-type histogram, the tool histogram, and the line numbers of failing results.

The tool histogram shows what kind of session ran. Counting Bash calls against lint runs can identify a repetition problem on its own.

## `errors`

Every failing result, one per line, classified as `hook-block`, `permission`, `environment`, `lint`, or `nonzero`.

The counts here answer different questions. The `is_error` flag counts what the harness marked as failed. This subcommand counts more, because a shell command that exits nonzero comes back as an ordinary result and a linter reporting findings does too. Say which count a figure came from.

## `loops`

Clusters repeated calls of the same shape, ranked by rounds. `--min-rounds N` sets how few rounds still count, default 3.

A pair of calls counts as one attempt when the signature matches. For Bash that signature is the recipes and commands invoked rather than the arguments, so repeated edit-then-relint rounds group into one cluster. Calls more than 40 records apart start a new cluster.

Rounds beyond the first are the wasted round trips. Rank findings by this number.

## `lint`

Linter rule frequency, plus the distribution that matters more than the total. Many failing runs each reporting one or two findings needs a different fix than a few runs reporting many at once. `--top N` lists more rules.

## `grep`

```text
session.py grep <transcript> 'pattern' [--context N] [--kind KIND] [--range LO HI] [--ignore-case] [--first]
```

Searches the decoded content blocks, so what prints matches what the model saw. Shell tools searching the raw file find the record and print it as one escaped line instead.

`--kind` narrows to `TEXT`, `THINK`, `USE:Bash`, `USE:Edit`, or `RES`. Reading `THINK` shows what the agent believed at the time, which is often where an error begins.

## `show`

```text
session.py show <transcript> 361,408,1938  # ranges work too: 40-45
```

Prints whole records, decoded. Use it once a report has given you a specific line number. `--width` limits each block.

## `meta`

Prints `SESSION_ID`, `SESSION_DATE`, `RECORDS` and `SIZE_MB` as shell-consumable assignments. `new-retro.sh` uses it so the retro directory takes its date from the session's own last record rather than from whenever the scaffolding runs.
