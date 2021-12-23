---
title: koji
homepage: https://github.com/its-danny/koji
tagline: |
  🦊 An interactive CLI for creating conventional commits.
---

To update or switch versions, run `webi koji@stable` (or `@v2`, `@beta`, etc).

**Note**: You should install git before installing koji.

## Files

These are the files that are created and/or modified with this installer:

```
~/.config/envman/PATH.env
~/.local/bin/koji
~/.local/opt/koji-VERSION/bin/koji
```

## Cheat Sheet

`koji` is an interactive CLI for creating
[conventional commits](https://www.conventionalcommits.org/en/v1.0.0/), ran in
place of `git commit`.

### Using koji

```bash
cd dev/work-stuff
# Do some work
cd dev/work-stuff
git add .env.production

# Create a conventional commit with koji
# in place of `git commmit`
koji
```

### With emoji

Passing `-e` or `--emoji` to `koji` will prepend your commit message with an
emoji related to the commit type. The default emoji can be seen
[here](https://github.com/its-danny/koji/blob/main/meta/config/koji-default.toml).

You can also use shortcodes (`:pinched_fingers:`) in the scope, summary, or
body.

### Autocomplete

Passing `-a` or `--autocomplete` to `koji` will enable autocomplete for the
scope prompt. This scans your commit history to collect previous scopes, so it
does slow down the startup a bit.

For reference, ran inside the [angular](https://github.com/angular/angular) repo
with 22k commits:

```
koji      0.00s
koji -a   0.40s
```

### As a git hook

If you're using [rusty-hook](https://github.com/swellaby/rusty-hook), set this
in your `.rusty-hook.toml` file.

```toml
prepare-commit-msg = "koji --hook"
```

Similar should work for any hook runner, just make sure you're using it with the
`prepare-commit-msg` hook as it writes the commit message to `COMMIT_EDITMSG`.

### Use custom commit types

You can add custom commit types via a `koji.toml` file in the working directory.
Some examples can be found
[here](https://github.com/its-danny/koji/blob/main/meta/config).
