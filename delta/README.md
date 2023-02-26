---
title: delta
homepage: https://github.com/dandavison/delta
tagline: |
  delta: A syntax-highlighting pager for git and diff output
---

To update or switch versions, run `webi delta` (or `@0.9.1`, `@0.9.0`, etc).

**Note**: You should install [git](./git) before installing `delta`.

### Files

These are the files that are created and/or modified with this installer:

```text
~/.config/envman/PATH.env
~/.gitconfig
~/.local/bin/delta
~/.local/opt/delta-VERSION/bin/delta
```

## Cheat Sheet

> `delta` gives you GitHub-style diffs, with word-level diff coloring, right in
> your trusty rusty terminal.

![](https://user-images.githubusercontent.com/52205/65248525-32250480-daea-11e9-9965-1a05c6a4bdf4.png)

Here we'll cover:

- **The install**: which files are added or changed
- **Configuration**: how to set a syntax theme
- **Preview**: how to list or show the color schemes
- **Manual Config**: how to turn `delta` on or off for git diffs

For the full set of options, be sure to check out the helpful
[README](https://github.com/dandavison/delta).

## How to set delta's color scheme

Delta uses `~/.gitconfig` for most of its options.

Set `delta.syntax-theme` to change the color scheme:

```sh
git config --global delta.syntax-theme 'Coldark-Dark'
```

## How to list / preview delta's themes

You can list all available themes with `--list-syntax-themes`, or see each color
schemes in action with `--show-syntax-themes`:

```sh
delta --list-syntax-themes --dark
delta --show-syntax-themes --dark
```

You can also show only light or dark themes:

```sh
delta --list-syntax-themes --light
delta --show-syntax-themes --light
```

```sh
delta --list-syntax-themes --dark
delta --show-syntax-themes --dark
```

Here's the current list, for convenience:

### Dark Syntax Themes

```text
1337
Coldark-Cold
Coldark-Dark
DarkNeon
Dracula
Monokai Extended
Monokai Extended Bright
Monokai Extended Origin
Nord
OneHalfDark
Solarized (dark)
Sublime Snazzy
TwoDark
Visual Studio Dark+
ansi
base16
base16-256
gruvbox-dark
zenburn
```

### Light Syntax Themes

```text
GitHub
Monokai Extended Light
OneHalfLight
Solarized (light)
gruvbox-light
```

## How to manually configure git to use delta

You can use `git config --global` to get or set any arbitrary option of
`~/.gitconfig`.

```sh
git config --global page.diff delta
git config --global page.show delta
git config --global page.log delta
git config --global page.blame delta
git config --global page.reflog delta

git config --global interactive.diffFilter 'delta --color-only'

git config --global delta.syntax-theme 'Coldark-Dark'
```

Your `~/.gitconfig` will then contain these sections and options:

```gitconfig
[pager]
    diff = delta
    show = delta
    log = delta
    blame = delta
    reflog = delta

[interactive]
    diffFilter = delta --color-only

[delta]
    syntax-theme = Coldark-Dark
```
