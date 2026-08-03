---
name: release
description: Cut a vale-ai-tells release end-to-end. Versions the changelog entry, bumps the package pins in the README, commits through the commit skill, tags, and waits for the workflow that publishes the three zips. Use when the operator asks to release, tag, or publish a version of this repository, and when a task ends in one.
argument-hint: [vX.Y.Z]
allowed-tools: Bash, Read, Edit, Skill
---

# Release

Perform a full release for version $ARGUMENTS.

## 1. Pre-flight

- Run `git status`. Working directory must show no changes and stay on `main`.
- Run `git log --oneline -3`. Confirm the tip commit matches what you want tagged.
- Check version format: must match `vMAJOR.MINOR.PATCH`
- Get the previous version tag for use in step 4: `git tag --sort=-version:refname | grep "^v" | head -1`

<!-- vale Google.Headings = NO -->

## 2. Update CHANGELOG.md

Read CHANGELOG.md and make these edits:

1. Replace `## [Unreleased]` with `## [$ARGUMENTS_NO_V] - YYYY-MM-DD`, using today's date. The heading uses the version without the leading `v` to match the existing convention and to match the link reference added in step 3 (rumdl will report `MD053 Unused link/image reference` if the two get out of sync).
2. Insert a new empty `## [Unreleased]` section before it
3. Add a comparison link at the bottom of the file, before the current top link: `[$ARGUMENTS_NO_V]: https://github.com/tbhb/vale-ai-tells/compare/PREV_TAG...$ARGUMENTS` where PREV_TAG refers to the tag found in step 1 and ARGUMENTS_NO_V strips the leading `v`

**Writing CHANGELOG entries**: `Metacommentary` uses `scope: raw`, which bypasses `<!-- vale off -->` inline suppression. Don't quote literal trigger phrases from that rule (the `Let's [verb]` patterns) in the CHANGELOG. Paraphrase them instead, as in v1.4.0.

## 3. Update README.md

<!-- vale Google.Headings = YES -->

The release workflow builds three packages at every tag (`ai-tells.zip`, `ai-tells-commits.zip`, `ai-tells-experimental.zip`). Bump the version in every `releases/download/vX.Y.Z/...` URL in the README so all package references point at the new tag.

Use `grep -n "releases/download" README.md` to enumerate every occurrence before editing.

## 4. Pre-commit checks

Run:

- `mise run repotools:lint-yaml`: confirm any new YAML files pass
- `mise run test-clean`: confirm false positives file remains clean

## 5. Commit

Invoke the `commit` skill, telling it to stage `CHANGELOG.md` and `README.md` and nothing else, and to use `chore: release $ARGUMENTS` as the subject. That skill owns the `COMMIT_AGENTMSG` draft, the `Assisted-by` and `Signed-off-by` trailers the `commit-trailers` hook requires, and the gates. A hand-written `git commit` here fails that hook, since a bare subject carries no trailers.

Keep the body **short and trigger-free**. The commit-msg hook lints the message with all ai-tells rules, and a release commit has little to explain beyond the version. Never name a flagged phrase or token in it.

## 6. Publish

Run:

```sh
mise run release $ARGUMENTS
```

This creates the annotated tag (using `-a -m`), pushes the commit and tag, then waits for the GitHub Actions release workflow to complete. It extracts the CHANGELOG entry and updates the release notes automatically.

## 7. Verify

Run `gh release view $ARGUMENTS` to confirm:

- Release notes match the CHANGELOG entry
- The "Full Changelog" comparison link appears and points to the right range
- All three package assets appear in the release: `ai-tells.zip`, `ai-tells-commits.zip`, `ai-tells-experimental.zip`
