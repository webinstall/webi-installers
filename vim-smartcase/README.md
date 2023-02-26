---
title: vim-smartcase
homepage: https://webinstall.dev/vim-smartcase
tagline: |
  vim smartcase is Vim's built-in semi-insensitive case matching
---

To update (replacing the current version) run `webi vim-smartcase`.

### Files

These are the files / directories that are created and/or modified with this
install:

```text
~/.vimrc
~/.vim/plugins/smartcase.vim
```

## Cheat Sheet

Vim search `/foo` is case-sensitive by default, but comes with options for
swapping that to be:

1. _case-insensitive_ by default - i.e. `/foo\c`
2. and _case-sensitive_ on mixed-case search - i.e. `/Foo\C`

This vim-smartcase plugin adds `set ignorecase` and `set smartcase` to your
`~/.vimrc`.

### Case Sensitivity in Vim

```vim
" treat everything in text and search as lowercase
set ignorecase
```

```vim
" treat mixed case as case sensitive
" requires 'ignorecase' to work
set smartcase
```

```vim
" explicit case-insensitive search for 'Bar'
" (\c can go anywhere in the search)
/Bar\c
/\cBar
/Ba\cr
```

```vim
" explicit case-sensitive search for 'Bar'
" (\C can go anywhere in the search)
/Bar\C
/\CBar
/Ba\Cr
```

### How to do this manually

Set `~/.vimrc`:

```vim
" make searches case-insensitive by default (i.e. /foo\c)
:set ignorecase
" make mixed-case searches case-sensitive by default  (i.e. /Foo\C)
:set smartcase

" fyi: you can put \c or \C before, after, or in the middle of a search
" ex: /Bar\c or /\cBar or /B\car
```

Available at
<https://github.com/webinstall/webi-installers/blob/master/vim-smartcase/smartcase.vim>
