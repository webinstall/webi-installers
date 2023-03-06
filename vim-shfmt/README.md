---
title: vim-shfmt
homepage: https://github.com/z0mbix/vim-shfmt
tagline: |
  vim-shfmt: a vim plugin for shfmt
---

To update (replacing the current version) run `webi vim-shfmt`. \
To update the config options, first remove `~/.vim/plugins/shfmt.vim`

### Files

These are the files / directories that are created and/or modified with this
install:

```text
~/.vim/pack/plugins/start/vim-shfmt/
~/.vim/plugins/prettier.vim
~/.vimrc
```

If [`shellcheck`](/shellcheck) and [`shfmt`](/shfmt) are not found, they will
also be installed.

## Cheat Sheet

`vim-shfmt` uses [shfmt](https://webinstall.dev/shfmt) to format your `bash`
scripts on save.

Use `:Shfmt` to run manually (or just save the file with `:w`).

This plugin comes with reasonable defaults, which install to
`~/vim/plugins/shfmt.vim`:

```vim
let g:shfmt_extra_args = '-i 4 -sr -ci -s'
let g:shfmt_fmt_on_save = 1
```

### How to install and configure manually

1. Clone `vim-shfmt` into your `~/.vim/pack/plugins/start`:

   ```sh
   mkdir -p ~/.vim/pack/plugins/start/
   git clone --depth=1 https://github.com/CHANGEME/EXAMPLE.git ~/.vim/pack/plugins/start/shfmt
   ```

2. Create the file `~/.vim/plugins/shfmt.vim`. Add the same contents as
   <https://github.com/webinstall/webi-installers/blob/master/vim-shfmt/shfmt.vim>,
   which will look something like this:

   ```vim
   " ~/.vim/plugins/shfmt.vim

   " 4 indents, space between redirects, indented case statements, simplify
   let g:shfmt_extra_args = '-i 4 -sr -ci -s'
   let g:shfmt_fmt_on_save = 1

   " auto run on .sh and .bash files
   augroup LocalShell
       autocmd!

       autocmd BufWritePre *.sh,*.bash Shfmt
   augroup END
   ```

3. Update `~/.vimrc` to source that plugin:
   ```vim
   " shfmt: reasonable defaults from webinstall.dev/vim-shfmt
   source ~/.vim/plugins/shfmt.vim
   ```
