---
title: vim-ale
homepage: https://github.com/dense-analysis/ale
tagline: |
  ALE: allows you to lint while you type.
---

To update (replacing the current version) run `webi vim-ale`.

## Cheat Sheet

> ALE (Asynchronous Lint Engine) is a plugin providing linting (syntax checking
> and semantic errors) in NeoVim 0.2.0+ and Vim 8 while you edit your text
> files, and acts as a Vim Language Server Protocol client.

ALE is the spiritual successor to Syntastic.

This installer includes a few reasonable defaults.

### How to install and configure manually

```sh
mkdir -p ~/.vim/pack/plugins/start/
git clone --depth=1 https://github.com/dense-analysis/ale.git ~/.vim/pack/plugins/start/ale
```

`.vimrc`:

```vim
" ALE: reasonable defaults from webinstall.dev/vim-ale
source ~/.vim/plugins/ale.vim
```

`.vim/plugins/ale.vim`:

```text
" turn on the syntax checker
syntax on

" don't check syntax immediately on open or on quit
let g:ale_lint_on_enter = 0
let g:ale_lint_on_save = 1

" error symbol to use in sidebar
let g:ale_sign_error = '☢️'
let g:ale_sign_warning = '⚡'

" show number of errors
function! LinterStatus() abort
    let l:counts = ale#statusline#Count(bufnr(''))
    let l:all_errors = l:counts.error + l:counts.style_error
    let l:all_non_errors = l:counts.total - l:all_errors
    return l:counts.total == 0 ? 'OK' : printf(
        \   '%d⨉ %d⚠ ',
        \   all_non_errors,
        \   all_errors
        \)
endfunction
set statusline+=%=
set statusline+=\ %{LinterStatus()}

" format error strings
let g:ale_echo_msg_error_str = 'E'
let g:ale_echo_msg_warning_str = 'W'
let g:ale_echo_msg_format = '[%linter%] %s [%severity%]'
```
