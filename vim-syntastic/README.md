---
title: vim-syntastic
homepage: https://github.com/vim-syntastic/syntastic
tagline: |
  Syntastic runs files through external syntax checkers and displays any resulting errors to the user.
---

## Updating `vim-syntastic`

```sh
webi vim-syntastic
```

## Cheat Sheet

`vim-syntastic` has been superseded by
[ALE](https://github.com/dense-analysis/ale), but it lives on in my heart, my
`.vim`, and my `.vimrc`.

### How to install manually

```sh
git clone --depth=1 https://github.com/vim-syntastic/syntastic.git ~/.vim/pack/plugins/start/vim-syntastic
```

### How to configure in `.vimrc`

`.vimrc`:

```text
" manually set plugin to use bash - not zsh, fish, etc
set shell=bash

" add this if packages don't load automatically
" or remove it otherwise
packloadall

" turn on the syntax checker
syntax on

" don't check syntax immediately on open or on quit
let g:syntastic_check_on_open = 1
let g:syntastic_check_on_wq = 0
```

### How to configure language-specific linters

```text
let g:syntastic_javascript_checkers = ['jshint']
let g:syntastic_go_checkers = ['go', 'golint', 'errcheck']
```
