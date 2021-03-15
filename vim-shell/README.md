---
title: vim-shell
homepage: https://webinstall.dev/vim-spell
tagline: |
  vim shell sets the default shell for vim
---

To update (replacing the current version) run `webi vim-shell`.

## Cheat Sheet

> `set shell=bash`, always

Especially if you use a non-bash-compatible shell, such as [fish](/fish), you
should set `set shell=bash` as the **first line** in your `~/.vimrc`.

This script does that for you.

### Why set bash as your vim shell?

Any vim plugin that uses shell scripting will assume _bash_ - just because
that's the way the world is.

Even if you have a mostly-bash-compatible shell, such as _zsh_, it's a good idea
to set the vim shell to bash, just to avoid any compatibility issues.
