---
title: beyond-shell
homepage: https://webinstall.dev/beyond-shell
tagline: |
  meta package for Beyond Code workshops
---

To update, run the relevant installers individually. For example:
`webi node@lts`.

### Files

These are the files / directories that are created and/or modified with this
install:

```text
~/bin
~/.config/envman/alias.env
~/.config/envman/PATH.env
~/.iterm2/
~/.local/bin/
~/.local/opt/
~/.local/share/font/ (or ~/Library/Fonts)
~/.vim/pack/plugins/start/
~/.vim/plugins/
~/.vimrc
```

## Cheat Sheet

> Installs the format and linter tools and code you'll need for the Beyond Code
> Shell Scripting Workshop

This meta package will install the full set of plugins and settings we
recommended.

## Prerequisites for Windows

- https://webinstall.dev/wsl
- https://webinstall.dev/nerdfont

## Post Install for macOS

- https://webinstall.dev/iterm2-themes
- https://webinstall.dev/nerdfont

## What's installed?

- Formatters & Linters
  - [`prettier`](/prettier)
  - [`shellcheck`](/shellcheck)
  - [`shfmt`](/shfmt)
- Vim Plugins & Config
  - [vim-leader](/vim-leader)
  - [vim-shell](/vim-shell)
  - [vim-sensible](/vim-sensible)
  - [vim-viminfo](/vim-viminfo)
  - [vim-lastplace](/vim-lastplace)
  - [vim-smartcase](/vim-smartcase)
  - [vim-spell](/vim-spell)
  - [vim-ale](/vim-ale)
  - [vim-prettier](/vim-prettier)
  - [vim-shfmt](/vim-shfmt)
  - [vim-whitespace](/vim-whitespace)
- Commandline Tools
  - [`aliasman`](/aliasman)
  - [`bat`](/bat)
  - [`curlie`](/curlie)
  - [`jq`](/jq)
  - [`pathman`](/pathman)
  - [`ssh-pubkey`](/ssh-pubkey)
  - [`webi`](/webi)
- Aliases
  - `cat='bat --style=plain --pager=none'`
  - `curl=curlie`
  - `setalias='aliasman'`
- System
  - [iterm2](/iterm2)
  - [fish](/fish)
  - [NerdFont](/nerdfont)
  - git
  - vim
  - zip
