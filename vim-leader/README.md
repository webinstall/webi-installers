---
title: vim-leader
homepage: https://webinstall.dev/vim-leader
tagline: |
  vim leader maps Space as Leader, keep Backslash and Comma as aliases
---

To update (replacing the current version) run `webi vim-leader`.

### Files

These are the files / directories that are created and/or modified with this
install:

```text
 ~/.vimrc
```

## Cheat Sheet

> `let mapleader = " "`

The `<Leader>` key is typically used for your own custom shortcuts.

By default it's mapped to `\` (backslash) - a legacy from a time when `\` was in
a more accessible place - but most people remap it to `,` or `` (space).

This vim-leader plugin makes Space the Leader key, but also remaps `\` and `,`
as aliases.

### How to configure manually

The Leader key **_MUST_** be defined before any mappings that use it (probably
before any plugins) - pretty much the first thing in your `~/.vimrc`.

```vim
let mapleader = ' '
nmap <bslash> <space>
nmap , <space>
```
