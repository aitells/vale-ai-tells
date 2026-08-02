---
name: resolve-rebase-conflicts
license: Apache-2.0
description: >-
  Settle the conflicts a stopped rebase left behind. Mechanical ones resolve without asking and the rest arrive with the evidence in front of you. Every path gets a classification first. An append-only sorted list becomes the verified union of both sides. A generated file takes one side whole and waits for its generator. Everything else is a real disagreement with what each side changed printed beside it. The rebase skill calls this at every stop. Use it directly whenever a rebase or cherry-pick stops on a conflict and the user asks to resolve it.
hooks:
  PreToolUse:
    - matcher: Bash
      hooks:
        - type: command
          command: "${CLAUDE_PROJECT_DIR}/.claude/skills/resolve-rebase-conflicts/scripts/guard-resolve.sh"
---

# Resolve rebase conflicts

Settle every conflicted path and stage it, so the rebase can advance. This skill ends there. Continuing the replay and verifying the result belong to the `rebase` skill.

A guard hook runs alongside. It refuses `--ours` and `--theirs`, which mean the opposite of what they read during a rebase, and it refuses staging a file that still carries markers.

## The inversion, once

During a rebase git checks out the base and replays your commits onto it. Your work is the side arriving, so git calls it `--theirs`, and the base you are moving onto becomes `--ours`. Every intuition about which word means which runs backwards here, and a wrong pick resolves cleanly and stays wrong.

Nothing in this skill uses either word. The sides are:

- `base-side` is the commit the branch replays onto. git calls it `--ours`, and the index calls it stage 2.
- `replayed-side` is the commit git is replaying right now. git calls it `--theirs`, and the index calls it stage 3.

The scripts read the index stages rather than the marker labels, so the naming holds under whatever marker style the repository sets.

## Marker shape

With `merge.conflictStyle` set to `diff3` or `zdiff3`, a conflict carries three sections rather than two:

```text
<<<<<<< HEAD
the base-side content
||||||| <ancestor label>
what both sides started from
=======
the replayed-side content
>>>>>>> <commit> (<subject>)
```

That `|||||||` section is the common ancestor, and it's the most useful part of the block: it says what each side changed rather than only what each side now holds. The default `merge` style omits it. Handle both, and never assume the two-way form.

A bare `=======` line isn't a marker on its own. It underlines a setext heading in ordinary Markdown, so the scripts here match only `<<<<<<<`, `|||||||`, and `>>>>>>>`.

## Step 0: open the task list

Create these with `TaskCreate`, then move each through `in_progress` and `completed`.

1. Classify every conflicted path
2. Resolve the mechanical ones
3. Take a whole side where that's the answer
4. Read the rest, and stage what you resolved
5. Hand back

Where a class turns out empty, close its task and say so rather than deleting it. Which classes the stop produced is part of the report at the end.

The scripts stop with a plain message when no rebase is in progress. Say that and hand back, because nothing here applies outside one.

## Step 1: classify before editing anything

```text
bash .claude/skills/resolve-rebase-conflicts/scripts/classify-conflicts.sh
```

One call reads every unmerged path and says what shape its conflict has, with the evidence for the claim printed beside it. Read that output before opening a single file.

The classes:

| Class | What it means | What to do |
| --- | --- | --- |
| `sorted-union` | All three versions sorted and unique, and neither side removed a line | `resolve-union.sh`, no confirmation |
| `regenerate` | The repository declares the path generated | `take-side.sh <path> base-side`, then run the generator after the rebase |
| `token-union` | Both sides extended the same line with extra tokens | Apply the printed proposal once the operator confirms the ordering |
| `content` | A real disagreement | Read what each side changed, then resolve by hand |

For a content conflict the script also prints what each side changed against the common ancestor. The markers can't show you that, and it's what settles the resolution.

## Step 2: resolve the mechanical ones

```text
bash .claude/skills/resolve-rebase-conflicts/scripts/resolve-union.sh <path> [path ...]
```

An append-only sorted list conflicts on nearly every rebase, and the answer comes out the same every time: every line either side has, sorted, once each. A word list, a spelling dictionary, a vocabulary file. Asking an operator to confirm that means asking them to rubber-stamp arithmetic.

Safety comes from the condition rather than the filename. The script refuses unless all three versions really do sort cleanly under the C collation with no duplicate line, and unless both sides kept every line the ancestor had. Those two conditions are what make a union provably lossless. A file that stops meeting them stops resolving here, which is what keeps a name-based shortcut from outliving the property it assumed.

After writing, the script re-derives the union from the index stages and compares the two. The result must carry exactly the lines the two sides carry between them. No duplicates, and still sorted. A resolution that dropped a line fails there rather than in a lint run three commits later.

Don't confirm any of this with the operator. Report it in the summary at the end.

## Step 3: take a whole side where that's the answer

```text
bash .claude/skills/resolve-rebase-conflicts/scripts/take-side.sh <path> base-side
bash .claude/skills/resolve-rebase-conflicts/scripts/take-side.sh <path> replayed-side
```

A generated file is the clear case. Merging two versions of machine output means nothing, because the generator is about to overwrite both. Take either side and move on. The `rebase` skill's verification names the path again at the end, so the regeneration doesn't get forgotten.

A `delete/modify` conflict is the other case, and it isn't mechanical. One side removed the file and the other edited it, so the decision needs the intent behind the removal. Find it, say what you found, then take a side.

## Step 4: read the rest

For a `content` conflict, work from what each side was trying to do rather than from the marker block. The classifier already printed both diffs against the common ancestor. Where you need more:

```text
git diff :1:<path> :2:<path>    # what the base-side changed
git diff :1:<path> :3:<path>    # what the replayed-side changed
```

Resolve so that both intents survive. Keeping one side's edit and quietly dropping the other is the failure to watch for, and afterwards it looks identical to a clean resolution. Nothing you can run at this point tells the two apart. That gap is the reason the `rebase` skill range-diffs the whole branch at the end rather than trusting that the replay applied.

One thing in a `token-union` proposal needs the operator: the ordering. Nobody disputes the union of the additions, but where those new tokens belong in the line is a judgement about how the file reads. Print the proposal, ask, apply the answer.

Stage what you resolved, by name:

```text
git add -- path/one path/two
```

Never `git add -A` or `git add .`. During a rebase those sweep in whatever an earlier commit in the replay left behind. The guard refuses both, along with any file that still carries markers.

## Step 5: hand back

Say what each path was and how you resolved it. Name anything you took a whole side on, and anything a generator still has to rewrite.

Then return to the `rebase` skill, which continues the replay through `continue-rebase.sh`. That script reads the staged blobs for markers once more before it advances.

Where a stop looks like the branch came off the wrong base entirely, say so instead of grinding through the rest. `git rebase --abort` costs nothing.

## A note on rerere

Where `rerere.enabled` is on, git replays resolutions it recorded during earlier rebases and stages them without stopping. Those paths never surface as conflicts, so nothing here classifies them and nothing has read them since the recording. `rebase-status.sh` lists them under `staged without stopping`. Read any that the stopped commit also touches. A resolution git recorded against different surrounding code can apply cleanly and still mean something else now.

## Preconditions

- a rebase in progress under the merge backend, which is git's default
- `python3` on the path, which the classifier and the union resolver both use

The scripts check both and stop with a plain message when either is missing.
