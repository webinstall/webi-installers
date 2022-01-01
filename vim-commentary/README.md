---
title: vim-commentary
homepage: https://github.com/tpope/vim-commentary
tagline: |
  Toggle blocks of line comments.
---

To update (replacing the current version) run `webi vim-smartcase`.

### Files

These are the files / directories that are created and/or modified with this
install:

```text
~/.vimrc
~/.vim/pack/plugins/start/vim-commentary/
~/.vim/plugins/smartcase.vim
```

## Cheat Sheet

> Makes it super easy to toggle entire blocks of comments.

```vim
gc
```

- `v` to enter visual model
- `hjkl` (or arrow keys) to select lines
- `gc` to toggle comments on or off

### How to add file types

Update `~/.vim/plugins/commentary.vim` with a line like this:

```vim
autocmd FileType apache setlocal commentstring=#\ %s
```

### How to do Advanced Vim-Nerd Stuff

All the typical navigation applies:

> Use `gcc` to comment out a line (takes a count), `gc` to comment out the
> target of a motion (for example, `gcap` to comment out a paragraph), `gc` in
> operator pending mode to target a comment. You can also use it as a command,
> either with a range like `:7,17Commentary`, or as part of a `:global`
> invocation like with `:g/TODO/Commentary`. - The Official README
