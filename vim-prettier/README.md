---
title: vim-prettier
homepage: https://github.com/prettier/vim-prettier
tagline: |
  vim-prettier adds Prettier support for Vim.
---

To update (replacing the current version) run `webi vim-prettier`. \
To update the config options, first remove `~/.vim/plugins/prettier.vim`

### Files

These are the files / directories that are created and/or modified with this
install:

```text
~/.vim/pack/plugins/start/vim-prettier/
~/.vim/plugins/prettier.vim
~/.vimrc
```

If [`node`](/node) and [`prettier`](/prettier) are not found, they will be also
installed.

## Cheat Sheet

> `vim-prettier` is a vim plugin wrapper for prettier, pre-configured with
> custom default prettier settings.

You'll also need to install [`ALE`](https://webinstall.dev/vim-ale) (part of
[`vim-essentials`](https://webinstall.dev/vim-essentials)) or
[`syntastic`](https://webinstall.dev/vim-syntastic) first.

### How to install by hand

```sh
git clone --depth=1 https://github.com/prettier/vim-prettier ~/.vim/pack/plugins/start/vim-prettier
```

### How to configure your `.vimrc`

```vim
" don't check syntax immediately on open or on quit
let g:syntastic_check_on_open = 1
let g:syntastic_check_on_wq = 0

" we also want to get rid of accidental trailing whitespace on save
autocmd BufWritePre * :%s/\s\+$//e
```

```vim
"""""""""""""""""""""""""""
" Prettier-specific options "
"""""""""""""""""""""""""""

" format as-you-type is quite annoying, so we turn it off
let g:prettier#autoformat = 0

" list all of the extensions for which prettier should run
autocmd BufWritePre .babelrc,.eslintrc,.jshintrc,*.js,*.jsx,*.mjs,*.ts,*.tsx,*.css,*.less,*.scss,*.json,*.graphql,*.md,*.vue,*.yaml,*.html PrettierAsync
```

### How to install Prettier

With `webi`:

```sh
webi prettier
```

With `node`:

```sh
npm install -g prettier@2
```
