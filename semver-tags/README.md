---
title: semver-tags
homepage: https://github.com/catalystcommunity/semver-tags
tagline: |
  semver-tags: Calculate and create semantic version tags from conventional commits.
description:
  A CLI that reads your conventional commits and creates the next semantic
  version tag, for single repos, monorepos, and named release targets.
---

To update or switch versions, run `webi semver-tags@stable` (or `@v0.6.1`,
`@beta`, etc).

### Files

These are the files that are created and/or modified with this installer:

```text
~/.config/envman/PATH.env
~/.local/bin/semver-tags
~/.local/opt/semver-tags-VERSION/bin/semver-tags
```

## Cheat Sheet

> `semver-tags` reads your conventional commits. It calculates the next semantic
> version. It can create and push the tag for you.

### How to tag a release for the whole repo

Run this command on your main branch, after your CI tests pass:

```sh
semver-tags run
```

This command reads the commits since the last tag. It picks the next version. It
creates a tag like `v1.2.3`. It pushes the tag and the branch to `origin`.

### How to preview the next version first

Use `--dry_run` to see the result. Do not create or push a tag yet:

```sh
semver-tags run --dry_run
```

### How to tag one service in a monorepo

Use `--directories` to give one subdirectory its own tag. The last part of the
path names the tag:

```sh
semver-tags run --directories services/api --directories services/worker
```

This command can create the tags `api/v1.2.3` and `worker/v0.4.1`. A commit that
changes only `services/api` releases only `api`.

### How to tag several directories as one release

Use `--dir_group` to put more than one directory under one tag. Separate the
paths with commas. The first directory in the list names the tag:

```sh
semver-tags run \
  --dir_group "services/api,libs/shared" \
  --dir_group "services/worker,libs/shared"
```

A commit in `libs/shared` releases both `api` and `worker`. A commit in only
`services/api` releases only `api`.

### How to name a release target directly

Use `--target` when the tag name must not come from a path. Put the name before
an equals sign:

```sh
semver-tags run \
  --target "public-api=services/api,libs/shared" \
  --target "public-worker=services/worker,libs/shared"
```

### How to use semver-tags in a GitHub Actions workflow

Add `--github_action` to write the results as step outputs. Set `LOG_LEVEL` to
`ERROR` so log lines do not mix with the JSON output:

```yaml
- name: Tag release
  id: tag
  env:
    LOG_LEVEL: ERROR
  run: semver-tags run --github_action

- name: Use the new tag
  run: echo "Tagged ${{ steps.tag.outputs.full_versions }}"
```

Always check the exit status of `semver-tags run` before you use its output. A
non-zero exit status means the command did not create a tag.

### How to change which commit types bump the version

By default, `fix` makes a patch release and `feat` makes a minor release.
`BREAKING CHANGE` always makes a major release. Use `--patch_types` and
`--minor_types` to add more types:

```sh
semver-tags run --patch_types fix --patch_types holiday
```

Use `--allowed_types` to limit which types can trigger a release at all:

```sh
semver-tags run --allowed_types feat,fix
```

### How to also update short version tags

Use `--short-versions` to update the mutable `vMAJOR.MINOR` and `vMAJOR` tags
each time you release. This is useful for actions like
`uses: your-org/your-action@v1`:

```sh
semver-tags run --short-versions
```

### How to see all options

```sh
semver-tags run --help
```
