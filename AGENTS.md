# Agent instructions

Guidance for AI coding agents working in this repository. Read it alongside the per-tool documentation and any memory files the harness loads.

## Commit messages

Write [Conventional Commits](https://www.conventionalcommits.org/) (`type(scope): subject`) with a DCO `Signed-off-by` trailer, and keep the subject under 80 characters. AI assistance is credited with a kernel-style `Assisted-by: AGENT:VERSION [TOOL]` trailer placed before the sign-off. Never credit a model through `Co-authored-by`.

Draft every message in a repo-root `COMMIT_AGENTMSG` file before you run `git commit`. A gitignore entry keeps that file out of history, so it serves purely as a scratchpad:

1. Write the full message (subject, body, and trailers) to `COMMIT_AGENTMSG`.
2. Run `mise run lint-commit-msg` and resolve whatever it reports.
3. Commit the validated draft with `git commit -s -F COMMIT_AGENTMSG`.

The `commit-msg` stage runs four hooks from the shared [`repotools`](https://github.com/tbhb/repotools) repository: `commitlint` (the Conventional Commits shape and length bounds), `commit-trailers` (the trailer format and order), `vale-commit-msg` (prose, under this repo's own `ai-tells` and `ai-tells-commits` styles), and `cspell-commit-msg` (spelling). Run `mise run repotools:prek-install` once so the hooks run on every commit.

That hook stage is the real gate. `mise run lint-commit-msg` only previews it, so a clean recipe run predicts a clean commit without replacing the hook.

## Prose lint output

The toolchain defaults to the agent template: `mise run lint-prose`, `mise run lint-messages`, and the vale pre-commit hook all pass `--output=ai-tells-agent.tmpl`. Name the flag yourself only when invoking `vale` directly. The template prints one self-contained line per finding (location, severity, rule, the exact matched text, and the replacement parameter when the rule defines one) plus a totals line, so you can apply fixes without re-reading context through separate commands. Empty output means a clean run, and the exit code reports the result.

`ai-tells.zip` includes the template, tracked here at `styles/config/templates/ai-tells-agent.tmpl`, so a repository syncing the core style alone can name the flag. A `vale sync` puts it under `StylesPath/config/templates/`, where vale looks up an `--output` name.

Treat the output shape as a published interface. The prose-fix skills in [`repotools`](https://github.com/tbhb/repotools) parse it: they count findings with `grep -c '^[0-9]'` and read the `replace_with=` field to apply a correction. Reshaping a line or renaming a field breaks those skills and anything else reading the format, so a change there is a breaking change for consumers rather than a local edit.

## Drafting a document

Each recipe named so far runs one checker over many files, so a draft that clears `mise run lint-prose` can still fail spelling and structure afterwards, which is how a short document turns into four rounds of linting. `mise run lint-draft <file>` runs vale, cspell, and rumdl over one document and reports all three at once.

It also probes the path before accepting a clean run. Vale matches a path against the sections in `.vale.ini` exactly, and a path outside every section has an empty style list. Vale then reads that file and exits 0 without printing anything, which is what a clean document produces too. The recipe sends known-bad text through vale under the target's own path and reports `unscoped-path` rather than a pass. Silence from that probe means a draft under `styles/`, `tmp/`, or `.claude/` answers to nothing. Move it to a path `.vale.ini` names.

`mise run fix-prose-replacements <file>` then applies the findings whose rule defines a correction. The Google and proselint rules define one, `ai-tells.HouseStyle` does too, and the template prints it as `replace_with=` on the finding line. The script refuses any finding whose span no longer contains the quoted text, and it skips a pronoun contraction that follows a preposition, because a verdict from that is narrower breaks when the contraction goes in. What it leaves behind is what needs a decision.
