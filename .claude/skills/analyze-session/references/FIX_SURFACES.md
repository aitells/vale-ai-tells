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

Spawn all five in a single message. Each one gets this preamble, then its own area block:

```text
Agent({
  subagent_type: "Explore",
  description: "<AREA> recommendations",
  prompt: `Recommend fixes for one area of a session retrospective.

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
  to the reader as a chosen one.`,
})
```

## The area blocks

**Agent constructs.** Name the hook event, subagent type, or skill that removes a failure rather than reminding someone about it. Confirm what the harness offers before recommending it, because the event list changes between releases and naming an event that no longer exists wastes the reader's time. Spawn the `claude-code-guide` agent, or read the reference at <https://code.claude.com/docs/en/hooks> plus the guide at <https://code.claude.com/docs/en/hooks-guide>. Match the construct to the failure. Use `PostToolUse` for a check the agent keeps forgetting. Use `PreToolUse` to refuse a command outright, where exit 2 blocks the call. Use a subagent for work that would otherwise fill the calling context.

**Commit-time gates.** Look at `.pre-commit-config.yaml`, the commit-msg chain, and the CI workflows. Find what a gate would have caught earlier, and what a gate is catching too late to be cheap. Check whether a gate enumerates files through `git ls-files`, which excludes anything an agent just created and reports success without inspecting untracked work.

**Repo tooling.** Look at `mise.toml`, the task files it includes, and `tools/`. Find the script or task that turns a run of round trips into one call. A task reporting every finding at once costs less than a loop reporting them one at a time.

**Configuration.** Look at the linter configs, the ignore files, and the settings. Find a rule tuned wrong for how this repository works, one matching text it should exempt, and one whose fix is mechanical rather than editorial. Separate a rule needing a config change from a rule needing an upstream fix.

**Instructions.** Look at `AGENTS.md`, `CLAUDE.md`, and the skills. Find what no tool can enforce, and apply that test strictly. A rule a script could check belongs in the script, so recommend prose only where the decision needs real judgment.

## Synthesis stays in the calling session

Each agent sees one area. The calling session has the verified figures and the full set of findings no single agent had, and delegating synthesis to another agent discards that.

Where two agents recommend the same fix independently, treat the agreement as evidence rather than duplication and put that fix first. Where recommendations conflict, record the conflict in the retro instead of resolving it silently.
