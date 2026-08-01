# Agent instructions

Guidance for AI coding agents working in this repository. Read it alongside the per-tool documentation and any memory files the harness loads.

## Commit messages

Write [Conventional Commits](https://www.conventionalcommits.org/) (`type(scope): subject`) with a DCO `Signed-off-by` trailer, and keep the subject under 80 characters. AI assistance is credited with a kernel-style `Assisted-by: AGENT:VERSION [TOOL]` trailer placed before the sign-off. Never credit a model through `Co-authored-by`.

Draft every message in a repo-root `COMMIT_AGENTMSG` file before you run `git commit`. A gitignore entry keeps that file out of history, so it serves purely as a scratchpad:

1. Write the full message (subject, body, and trailers) to `COMMIT_AGENTMSG`.
2. Run `just lint-commit-msg` and resolve whatever it reports.
3. Commit the validated draft with `git commit -s -F COMMIT_AGENTMSG`.

The `commit-msg` stage runs four hooks from the shared [`pre-commit-hooks`](https://github.com/tbhb/pre-commit-hooks) repository: `commitlint` (the Conventional Commits shape and length bounds), `commit-trailers` (the trailer format and order), `vale-commit-msg` (prose, under this repo's own `ai-tells` and `ai-tells-commits` styles), and `cspell-commit-msg` (spelling). Run `just prek-install` once so the hooks fire on every commit.

That hook stage is the real gate. `just lint-commit-msg` only previews it, so a clean recipe run predicts a clean commit without replacing the hook.

## Prose lint output

The toolchain defaults to the agent template: `just lint-prose`, `just lint-messages`, and the vale pre-commit hook all pass `--output=ai-tells-agent.tmpl`. Name the flag yourself only when invoking `vale` directly. The template prints one self-contained line per finding (location, severity, rule, the exact matched text, and the replacement parameter when the rule defines one) plus a totals line, so you can apply fixes without re-reading context through separate commands. Empty output means a clean run, and the exit code carries the result.

The template is tracked at `styles/config/templates/ai-tells-agent.tmpl`, which puts it inside the `ai-tells-experimental` release zip alongside the Tengo scripts.
