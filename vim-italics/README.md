---
title: vim-italics
homepage: https://webinstall.dev/vim-italics
tagline: |
  vim-italics is refactors the text to italics.
---

To update (replacing the current version) run `webi vim-italics`.


## Cheat Sheet

Vim-italics turns text to italics.

### How to install manually

```ruby
highlight htmlItalic gui=italic ctermfg=214
```

You'll need a font with an italic set and a terminal capable of displaying italics. Also, if you're using a color scheme other than the default, the above line should come after the color scheme is loaded in your ```~/.vimrc``` so that the color scheme doesn't override it.

The cterm makes it work in the terminal and the gui is for graphical Vim clients.
