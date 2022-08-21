---
title: vim-go
homepage: https://github.com/fatih/vim-go
tagline: |
  vim-go adds Go language support for Vim.
---

To update (replacing the current version) run `webi vim-go`.

## Cheat Sheet

> `vim-go` provides integration with various official and 3rd party go tooling
> for linting, vetting, etc.

You'll also need to install [`ALE`](https://webinstall.dev/vim-ale) (part of
[`vim-essentials`](https://webinstall.dev/vim-essentials)) or
[`syntastic`](https://webinstall.dev/vim-syntastic) first.

### How to install by hand

```sh
git clone --depth=1 https://github.com/fatih/vim-go.git ~/.vim/pack/plugins/start/vim-go
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
" Golang-specific options "
"""""""""""""""""""""""""""

" tell syntastic that go, golint, and errcheck are installed
let g:syntastic_go_checkers = ['go', 'golint', 'errcheck']

" tell vim-go that goimports is installed
let g:go_fmt_command = "goimports"

" tell vim-go to highlight
let g:go_highlight_functions = 1
let g:go_highlight_methods = 1
let g:go_highlight_structs = 1
let g:go_highlight_operators = 1
let g:go_highlight_build_constraints = 1
```

### How to install go language tools

via `vim` with `:GoInstallBinaries`:

```sh
printf ':GoInstallBinaries\n:q\n' | vim -e
```

via `sh`:

```sh
# gopls
go install golang.org/x/tools/gopls

# golint
go install golang.org/x/lint/golint

# errcheck
go install github.com/kisielk/errcheck

# gotags
go install github.com/jstemmer/gotags

# goimports
go install golang.org/x/tools/cmd/goimports

# gorename
go install golang.org/x/tools/cmd/gorename

# goreturns
go install github.com/sqs/goreturns

# gotype
go install golang.org/x/tools/cmd/gotype
```
