---
name: release
description: Perform a vale-ai-tells release end-to-end
disable-model-invocation: true
argument-hint: [vX.Y.Z]
allowed-tools: Bash, Read, Edit
---

# Release

Perform a full release for version $ARGUMENTS.

## 1. Pre-flight

- Run `git status`. Working directory must be clean and on `main`.
- Run `git log --oneline -3`. Confirm the tip commit is what you want tagged.
- Validate version format: must match `vMAJOR.MINOR.PATCH`
- Get the previous version tag for use in step 4:
  `git tag --sort=-version:refname | grep "^v" | head -1`

## 2. Update CHANGELOG.md

Read CHANGELOG.md and make these edits:

1. Replace `## [Unreleased]` with `## [$ARGUMENTS] - YYYY-MM-DD` (today's date)
2. Insert a new empty `## [Unreleased]` section above it
3. Add a comparison link at the bottom of the file, above the current top link:
   `[$ARGUMENTS_NO_V]: https://github.com/tbhb/vale-ai-tells/compare/PREV_TAG...$ARGUMENTS`
   (where PREV_TAG is the tag found in step 1 and ARGUMENTS_NO_V strips the leading `v`)

**Writing CHANGELOG entries**: Be aware that `Metacommentary` uses `scope: raw`,
which bypasses `<!-- vale off -->` inline suppression. Do not quote literal
trigger phrases from that rule (the `Let's [verb]` patterns) in the
CHANGELOG. Paraphrase them instead, as was done in v1.4.0.

## 3. Update README.md

Find the line:

```ini
Packages = https://github.com/tbhb/vale-ai-tells/releases/download/vX.Y.Z/ai-tells.zip
```

and update the version to `$ARGUMENTS`.

## 4. Pre-commit checks

Run:

- `just lint-yaml`: confirm any new YAML files pass
- `just test-clean`: confirm false positives file is still clean

## 5. Commit

Stage only `CHANGELOG.md` and `README.md`:

```sh
git add CHANGELOG.md README.md
```

Commit message must be **short and trigger-free**. The commit-msg hook lints it
with all ai-tells rules. Use:

```text
chore: release $ARGUMENTS
```

Do NOT include the names of flagged phrases or tokens in the commit message body.

## 6. Publish

Run:

```sh
just release $ARGUMENTS
```

This creates the annotated tag (with `-a -m`, which is required), pushes the
commit and tag, then waits for the GitHub Actions release workflow to complete.
It extracts the CHANGELOG entry and updates the release notes automatically.

## 7. Verify

Run `gh release view $ARGUMENTS` to confirm:

- Release notes match the CHANGELOG entry
- The "Full Changelog" comparison link is present and correct
- The `ai-tells.zip` asset is attached
