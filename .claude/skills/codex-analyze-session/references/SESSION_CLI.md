# `session.py`

The query tool this skill uses. It reads a transcript line by line and prints totals with line numbers, so nothing needs the whole file in context.

It has a uv script shebang and declares which Python version it needs, so it runs directly:

```text
.agents/skills/codex-analyze-session/scripts/session.py <subcommand> <transcript> [options]
```

The preflight already runs `index`, `errors`, `loops` and `lint`, and leaves the full output in the retro's `artifacts/`. Run the tool directly when a report needs more detail than the preflight printed, or when the reports point at something worth searching for.

## `locate`

```text
session.py locate --contains 'some-distinctive-string' [--project SUBSTRING]
```

Finds dated transcript files by content or by the `cwd` in session metadata instead of guessing a directory name. Output is size, path, and match count, newest first.

A search with no hits proves nothing on its own. Confirm the same string matches some other transcript before concluding this session is absent.

## `index`

One pass over everything. Prints the record count, how many records are sidechain, the record-type histogram, the tool histogram, and the line numbers of failing results.

The tool histogram shows what kind of session ran. Counting process calls against lint runs can identify a repetition problem on its own.

## `errors`

Every likely failing result, one per line, classified as `permission`, `environment`, `lint`, or `nonzero`.

Codex transcript results don't expose a stable structured exit code, so this command recognizes failure text in the result envelope. Use its count to locate lines for inspection. Name the command behind every reported figure.

## `loops`

Clusters repeated calls of the same shape, ranked by rounds. `--min-rounds N` sets how few rounds still count, default 3.

A pair of calls counts as one attempt when the signature matches. For `exec`, that signature uses the nested tool plus the shell command or mise task shape rather than treating every process call alike. Calls more than 40 records apart start a new cluster.

Rounds beyond the first are the wasted round trips. Rank findings by this number.

## `lint`

Linter rule frequency, plus the distribution that matters more than the total. Many failing runs each reporting one or two findings needs a different fix than a few runs reporting many at once. `--top N` lists more rules.

## `grep`

```text
session.py grep <transcript> 'pattern' [--context N] [--kind KIND] [--range LO HI] [--ignore-case] [--first]
```

Searches the decoded content blocks, so what prints matches what the model saw. Shell tools searching the raw file find the record and print it as one escaped line instead.

`--kind` narrows to `TEXT`, `THINK`, `USE:exec`, another `USE:<tool>` name from the histogram, or `RES`. Reading `THINK` shows what the agent believed at the time, which is often where an error begins.

## `show`

```text
session.py show <transcript> 361,408,1938  # ranges work too: 40-45
```

Prints whole records, decoded. Use it once a report has given you a specific line number. `--width` limits each block.

## `meta`

Prints `SESSION_ID`, `SESSION_DATE`, `RECORDS` and `SIZE_MB` as shell-consumable assignments. `new-retro.sh` uses it so the retro directory takes its date from the session's own last record rather than from whenever the scaffolding runs.
