---
title: vim-rust
homepage: https://github.com/rust-lang/rust.vim
tagline: |
  vim-rust (rust.vim) adds Rust language support for Vim.
---

To update (replacing the current version) run `webi vim-rust`.

## Cheat Sheet

> `vim-rust` provides integration with `cargo check`, `rustfmt`, and other rust
> tooling.

You'll also need to install [`ALE`](https://webinstall.dev/vim-ale) (part of
[`vim-essentials`](https://webinstall.dev/vim-essentials)) or
[`syntastic`](https://webinstall.dev/vim-syntastic) first.

### How to install and configure by hand

1. Remove the previous version of rust.vim, if any:
   ```sh
   rm -rf ~/.vim/pack/plugins/start/rust.vim
   ```
2. Install `rust.vim` as a Vim8 package with `git`:
   ```sh
   mkdir -p ~/.vim/pack/plugins/start/
   git clone --depth=1 \
       https://github.com/rust-lang/rust.vim \
       ~/.vim/pack/plugins/start/rust.vim
   ```
3. Create `~/.vim/plugins/rust.vim`, as follows:

   ```vim
   " Reasonable defaults for rust.vim

   " run rustfmt on save
   let g:rustfmt_autosave = 1

   " run cargo check et al
   let g:ale_rust_cargo_use_check = 1
   let g:ale_rust_cargo_check_tests = 1
   let g:ale_rust_cargo_check_examples = 1
   ```

4. Edit `~/.vimrc` to include the config:
   ```vim
   " Rust: reasonable defaults for rust.vim
   source ~/.vim/plugins/rust.vim
   ```
