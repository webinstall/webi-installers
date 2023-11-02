---
title: vim-zig
homepage: https://github.com/ziglang/zig.vim
tagline: |
  vim-zig (zig.vim) adds zig language support for Vim.
---

To update (replacing the current version) run `webi vim-zig`.

## Cheat Sheet

> `vim-zig` provides integration with `zls`, `zig fmt`, and other zig tooling.

You'll also need to install [`ALE`](https://webinstall.dev/vim-ale) (part of
[`vim-essentials`](https://webinstall.dev/vim-essentials)) or
[`syntastic`](https://webinstall.dev/vim-syntastic) first.

### Files

```text
~/.vim/pack/plugins/start/zig.vim/
~/.vim/plugins/start/zig.vim
```

### How to install and configure by hand

1. Remove the previous version of zig.vim, if any:
   ```sh
   rm -rf ~/.vim/pack/plugins/start/zig.vim
   ```
2. Install `zig.vim` as a Vim8 package with `git`:
   ```sh
   mkdir -p ~/.vim/pack/plugins/start/
   git clone --depth=1 --single-branch master \
       https://github.com/zig-lang/zig.vim \
       ~/.vim/pack/plugins/start/zig.vim
   ```
3. Create `~/.vim/plugins/zig.vim`, as follows:

   ```vim
   " Reasonable defaults for zig.vim

   " run zig fmt on save
   let g:zig_fmt_autosave = 1
   ```
