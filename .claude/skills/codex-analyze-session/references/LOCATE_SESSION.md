# Locating a session

Use this when the operator named a session without giving a usable path. Reading transcript files in the calling session costs more context than the analysis that follows, so a fresh delegated agent runs the streaming locator and returns one line.

A fresh delegated agent with `fork_turns: "none"` is enough. Matching a file by its contents doesn't need judgment, and the answer is one path.

## The template

Fill in the search string, then call `spawn_agent` with a short task name, `fork_turns: "none"`, and this message:

```text
Find one Codex transcript and return its absolute path.

  Run this, where <SKILL> is the analyze-session skill directory:

    <SKILL>/scripts/session.py locate --contains '<SEARCH STRING>'

  It prints size, path, and match count per candidate, newest first.

  Try these in order until one matches, and report which one worked:
    1. --contains '<SEARCH STRING>'
    2. --contains '<SECOND SEARCH STRING>'
    3. --project '<REPO NAME>' with no --contains, listing every
       transcript for that project so the caller picks by size and date

  Return the absolute path alone when exactly one candidate matches.
  Return every candidate with its size and match count when more than
  one does. Say so plainly when nothing matches.

NEVER open or print a transcript. Each one can be megabytes. The locate
subcommand reads it line by line in the process and reports only metadata,
which is why you run it instead of reading rollout content into context.
```

## Choosing a search string

Pick a string likely to appear in that session and few others. A filename the session created works well, and so does an identifier it invented or a rule name from its own output. A thread ID isn't automatically unique as content because another session may quote it.

Avoid anything the repository already contains. A common word matches every transcript mentioning the project, and the agent returns a list rather than an answer.

## What to do with a null result

Zero hits proves nothing until the same string matches something else. A search matching no transcript may mean the session is absent, or may mean the string was wrong.

Give the agent a second string to try before concluding the session doesn't exist.

## A common mistake

Codex stores transcripts in dated directories instead of encoding the repository path in a project directory. A working directory doesn't reveal the transcript path. Search the session metadata or content instead.
