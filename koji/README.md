---
title: koji
homepage: https://github.com/cococonscious/koji
tagline: |
  🦊 An interactive CLI for creating conventional commits.
---

To update or switch versions, run `webi koji@stable` (or `@v2`, `@beta`, etc).

**Note**: You should install [git](/git) before installing koji.

## Cheat Sheet

> `koji` is an interactive CLI for creating [conventional commits][cc].

![](https://github.com/cococonscious/koji/raw/main/meta/demo.gif)

[cc]: https://conventionalcommits.org/en/v1.0.0/

You can use koji in one of two ways:

1. `koji` instead of `git commit`
2. `koji --hook` in `./.git/hooks/prepare-commit-msg` \
   (to be run by `git commit`)

Here's the shortlist of options we've found most useful:

```text
-e, --emoji - use emoji for commit summary (ex: `feat: ✨ ...`)
-a, --autocomplete - guess 'scope' based on commit history (slow on large projects)
--hook - expect to be run from 'git commit', rather than wrap it
```

### Files

These are the files that are created and/or modified with this installer:

```sh
~/.config/envman/PATH.env
~/.local/bin/koji
~/.local/opt/koji-VERSION/bin/koji
```

### How to use koji (standalone)

In this case, `koji` acts as a wrapper around `git commit`:

```sh
git add example.env

# same as `git commit`, but interactive
koji
```

### How to use koji as a commit hook

Just add `koji --hook` to your project's `.git/hooks/prepare-commit-msg`:

```sh
echo >> ./.git/hooks/prepare-commit-msg << "EOF"
#!/bin/sh
koji --hook
EOF

chmod a+x ./.git/hooks/prepare-commit-msg
```

```sh
# will run koji by way of prepare-commit-msg
git commit
```

### How to use Emoji

You can use `-e` (or `--emoji`) to prepend your commit message summary with the
relevant emoji for the commit type:

```sh
koji -e
```

As a git hook:

`.git/hooks/prepare-commit-msg`:

```sh
#!/bin/sh
koji --emoji --hook
```

You can also use _shortcodes_ (`:pinched_fingers:`) in the scope, summary, or
body.

### How to configure koji

You can configure koji via a custom config passed with `--config`, a
`.koji.toml` file in the project root, or a user config at
`~/.config/koji/config.toml`.

Here's an example of a custom commit type:

```toml
[[commit_types]]
name = "cust"
emoji = "✨"
description = "A custom commit type"
```

The default configuration can be seen in
[default.toml](https://github.com/cococonscious/koji/blob/main/meta/config/default.toml).
