---
title: vim-whitespace
homepage: https://webinstall.dev/vim-whitespace
tagline: |
  vim whitespace sets tab, whitespace, trailing whitespace rules to reasonable values
---

To update (replacing the current version) run `webi vim-whitespace`.

## Cheat Sheet

The idea that tabs should be 8 spaces wide is redonkulous.

This vim-whitespace plugin sets tabs to spaces (4 wide), trim trailing
whitespace, and makes whitespace handling consistent.

### How to configure manually

Create the file `~/.vim/plugins/whitespace.vim`. Add the same contents as
<https://github.com/webinstall/webi-installers/blob/master/vim-whitespace/whitespace.vim>.

That will look something like this:

```vim
" handle tabs as 4 spaces, in every direction, consintently
set tabstop=4
set shiftwidth=4
set smarttab
set expandtab
set softtabstop=4

" remove trailing whitespace on save
autocmd BufWritePre * :%s/\s\+$//e
```

You'll then need to update `~/.vimrc` to source that plugin:

```vim
" Tabs & Whitespace: reasonable defaults from webinstall.dev/vim-whitespace
source ~/.vim/plugins/whitespace.vim
```
