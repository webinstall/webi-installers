---
title: vim-mouse
homepage: https://webinstall.dev/vim-mouse
tagline: |
  vim mouse is Vim's built-in mouse support
---

To update (replacing the current version) run `webi vim-mouse`.

## Cheat Sheet

Vim has built-in mouse support.

It is turned off by default and when turned on may not behave exactly as
expected.

This vim-mouse plugin turns on mouse support with insert mode on click,
select-to-copy clipboard, and other GUI options.

### How to configure manually

Create the file `~/.vim/plugins/mouse.vim`. Add the same contents as
<https://github.com/webinstall/webi-installers/blob/master/vim-mouse/mouse.vim>.

That will look something like this:

```vim
" turn on mouse support
set mouse=a

" keep copy-on-select and other GUI options
set clipboard+=autoselect guioptions+=a

" enter insert mode on left-click
nnoremap <LeftMouse> <LeftMouse>i
```

You'll then need to update `~/.vimrc` to source that plugin:

```vim
" Mouse Support: reasonable defaults from webinstall.dev/vim-mouse
source ~/.vim/plugins/mouse.vim
```
