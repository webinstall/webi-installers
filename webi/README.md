---
title: Webi
homepage: https://webinstall.dev
tagline: |
  Webi is how developers install their tools.
---

## Updating `webi`

```sh
webi webi
```

Since `webi` is just a small helper script, it always updates on each use.

## Cheat Sheet

> `webi` is what you would have created if you automated how you install your
> common tools yourself: Simple, direct downloads from official sources,
> unpacked into `~/.local`, added to `PATH`, symlinked for easy version
> switching, with minimal niceties like resuming downloads and 'stable' tags.

- Easy to remember.
- No magic, no nonesense, no bulk.
- What you would have done for yourself.

You can install _exactly_ what you need, from memory, via URL:

```sh
curl https://webi.sh/node@lts | sh
```

Or via `webi`, the tiny `curl | sh` shortcut command that comes with each
install:

```sh
webi node@lts golang@stable flutter@beta rustlang
```

### webi PATHs

You can see exactly what PATHs have been edited:

```sh
pathman list
```

And where:

```sh
cat ~/.config/envman/PATH.env
```

### How to uninstall Webi

These are the files that are installed when you use [webinstall.dev](/):

```sh
# Mac, Linux
~/.local/bin/webi
~/.local/bin/pathman
~/.local/opt/pathman-*

# Windows
~/.local/bin/webi.bat
~/.local/bin/webi-pwsh.ps1
```

Assuming that you don't use `pathman` for anything else, you can safely remove
all of them. If you use [webinstall.dev](/) again in the future they will be
reinstalled.

Additionally, these files may be modified to update your `PATH`:

```sh
~/.bashrc
~/.profile
~/.config/fish/config.fish
~/.config/envman/PATH.env
```

It's probably best to leave them alone.

### How to uninstall Webi-installed programs

Except where noted otherwise (such as `wsl`) Webi installs everything into
`~/.local/bin` and `~/.local/opt`.

Some programs also use `~/.local/share` or `~/.config` - such as `postgres` and
`fish` - and some use program-specific directories - such as Go, which uses
`~/go/bin`.

If you want to remove any of them, simply deleting them should do well enough -
just check the Cheat Sheet for any special notes.

Here are some examples:

```sh
# Remove jq
rm -rf ~/.local/bin/jq
rm -rf ~/.local/jq-*/

# Remove node.js
rm -rf ~/.local/opt/node/
rm -rf ~/.local/opt/node-*/
```
