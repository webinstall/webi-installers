---
title: vim-example
homepage: https://github.com/CHANGEME/example
tagline: |
  Vim Example: A template for webi vim plugins.
---

To update (replacing the current version) run `webi vim-example`.

## Cheat Sheet

![](https://i.imgur.com/N2dVHJP.png)

> Replace this text with a nice summary, perhaps from the plugins documentation.

If there are some important key bindings, use a table like this:

| Key                     | Action                                               |
| ----------------------- | ---------------------------------------------------- |
| **Global Key Bindings** |                                                      |
| `<Leader>n`             | Move cursor to NERDTree                              |
| `ctrl+w`, w             | Rotate between open windows                          |
| `:e **/api.js<tab>`     | Open and edit file matching api.js, in any subfolder |

### How to install and configure manually

1. Place EXAMPLE into your `~/.vim/pack/plugins/start`:

   ```sh
   mkdir -p ~/.vim/pack/plugins/start/
   git clone --depth=1 https://github.com/CHANGEME/EXAMPLE.git ~/.vim/pack/plugins/start/example
   ```

2. Create the file `~/.vim/plugins/example.vim`. Add the same contents as
   <https://github.com/webinstall/webi-installers/blob/master/vim-example/example.vim>,
   which will look something like this:

   ```vim
   " ~/.vim/plugins/example.vim

   " default mappings for example
   nnoremap <leader>x :EXAMPLE<CR>
   ```

3. Update `~/.vimrc` to source that plugin:
   ```vim
   " example: reasonable defaults from webinstall.dev/vim-example
   source ~/.vim/plugins/example.vim
   ```
