# Recommending fixes

Verification runs identical prompts, because replication gains nothing from a division of labor. This step does the opposite. Each agent takes one area and reports only the fixes belonging to it, which keeps the recommendations distinct and the coverage wide.

Give every agent the retro directory rather than the transcript. The canned reports under `artifacts/` already summarize the session, so each agent spends its context on analysis instead of re-deriving numbers.

## The areas

| area | what to look for |
| ---- | ---------------- |
| Agent constructs | The hook event, subagent or skill that removes a failure outright |
| Commit-time gates | Anything belonging in prek, the commit-msg chain or CI |
| Repo tooling | The script or `mise` task that turns many round trips into one |
| Configuration | A linter rule or ignore file tuned wrong for how the repo works |
| Instructions | What only `AGENTS.md` or a skill can fix, because no tool does |

## The shared prompt

Spawn fresh delegated agents with `fork_turns: "none"`, batching the five areas when fewer than five slots are available. Each gets this preamble, then its own area block:

```text
Recommend fixes for one area of a session retrospective.

  RETRO: <RETRO DIRECTORY>
  Read RETRO.md for the findings, and artifacts/ for the figures behind
  them. artifacts/loops.txt ranks patterns by round trips wasted, which
  is what "worth fixing" means here.
  REPO: <ABSOLUTE PATH>

  YOUR AREA: <AREA BLOCK>

  Report only fixes belonging to your area. Say so plainly when a
  finding belongs to a different area, rather than stretching your
  recommendation to cover it.

  For each recommendation give: the finding it addresses, what you would
  build or change, the round trips it would have saved, and what it
  costs. State a cost for every one, because a recommendation without
  one gives the reader no way to compare it.

  Rank yours by round trips saved. Name anything you considered and
  rejected, with the reason, because a rejected option is worth as much
  to the reader as a chosen one.
```

## The area blocks

**Agent constructs.** Choose a verified Codex facility that removes the failure: a delegated agent, skill, script, repository gate, or documented user-level hook. Only recommend skill-scoped hooks after a probe proves enforcement. Keep filesystem writers in the parent when shared-worktree concurrency would be unsafe.

**Commit-time gates.** Inspect `.pre-commit-config.yaml`, the commit-msg chain, and CI. Identify failures a gate could catch earlier. A gate built on `git ls-files` misses new files and can report success without examining them.

**Repo tooling.** Collapse repeated calls into one task.

**Configuration.** Read the linter configs, ignore files, and settings. Look for a badly tuned rule, a missing exemption, or a mechanical correction. Separate local configuration defects from upstream defects, and state which owner can fix each one.

**Instructions.** Reserve prose for judgment. Put enforceable rules in scripts.

## Synthesis stays in the calling session

Each agent sees one area. The calling session has the verified figures and the full set of findings that no agent had alone, and delegating synthesis to another agent discards that.

Where two agents recommend the same fix independently, treat the agreement as evidence rather than duplication and put that fix first. Where recommendations conflict, record the conflict in the retro instead of resolving it silently.
