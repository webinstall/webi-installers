---
title: vim-gui
homepage: https://webinstall.dev/vim-gui
tagline: |
  vim-gui enables Vim's built-in support for mouse, clipboard, etc
---

To update (replacing the current version) run `webi vim-gui`.

## Cheat Sheet

Vim has built-in GUI support.

It is turned off by default and when turned on may not behave exactly as
expected.

This vim-gui plugin turns on mouse support with insert mode on click,
select-to-copy clipboard, and other GUI options.

### How to configure manually

Create the file `~/.vim/plugins/gui.vim`. Add the same contents as
<https://github.com/webinstall/webi-installers/blob/master/vim-gui/gui.vim>.

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
" Mouse Support: reasonable defaults from webinstall.dev/vim-gui
source ~/.vim/plugins/gui.vim
```
