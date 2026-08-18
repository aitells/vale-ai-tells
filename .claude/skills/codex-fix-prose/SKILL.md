---
name: codex-fix-prose
description: >-
  Clear vale and cspell findings on a settled document through an isolated Codex writer and an independent reviewer. Use when a draft's prose gates are red or repeated lint findings would pollute the parent context. Takes a target and its complete lint command.
---

# Orchestrate a prose fix

Keep findings and retries out of the parent context. Parse the request into a target and complete lint command, then run:

```text
bash .agents/skills/codex-fix-prose/scripts/preflight.sh <target> <lint command>
```

Stop on `BLOCKED`. On `PROCEED`, create a plan with `update_plan`: baseline, writer, mechanical verification, independent review, final lint.

Record the baseline before delegation:

```text
bash .agents/skills/codex-fix-prose/scripts/check-suppressions.sh --baseline <target>
```

Save the absolute `state:` path that command prints. It identifies this workflow and records its target. Until cleanup, the script refuses a second workflow on the same target. Pass the state to every delegated writer and reviewer in this run.

Delegate `codex-write-prose-fix` with `fork_turns: "none"`. Give it only the repository root, target, workflow state, lint command, and instruction to follow that skill. Wait for its terminal report. Never edit the target in the parent.

Run `check-suppressions.sh --verify <state> <target>`. Any finding means the run isn't clean. Delegate `codex-review-prose-fix` with `fork_turns: "none"`, giving it the repository root, target, and workflow state. If it returns changes required, save those findings in `<state>/notes`, delegate the writer again with the same minimal prompt, and repeat verification and review. Bound this writer/reviewer loop at three review rounds.

Finally run the complete lint command once in the parent. Always run `check-suppressions.sh --cleanup <state>` before returning once no delegated agent needs the state, even when the outcome is unresolved or blocked. Report `PROSE: CLEAN` only when the writer reported clean, the suppression check is silent, the independent reviewer returned `REVIEW: CLEAN`, and the final lint command passes. Otherwise return the short unresolved or blocked report. Mark each plan item as it completes.

Safety rules:

- Only the delegated writer may edit the target, and the target is the only file it may edit.
- Never change lint configuration, dictionaries, hooks, or suppression comments.
- Don't infer clean from silent output unless preflight proved the target has prose rules.
- Don't expose full lint findings in the parent response unless the workflow blocks and the operator needs a decision.
