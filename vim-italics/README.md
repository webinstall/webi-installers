---
title: vim-italics
homepage: https://webinstall.dev/vim-italics
tagline: |
  vim-italics sets vim to use underlines for italics
---

To update (replacing the current version) run `webi vim-italics`.

### Files

These are the files / directories that are created and/or modified with this
install:

```text
~/.vimrc
~/.vim/plugins/italics.vim
```

## Cheat Sheet

`vim` uses background highlighting for italics by default.

Many Terminal color themes use the same color for background highlighting as for
the cursor, which makes tracking the cursor difficult.

This swaps to italics to use underlines instead, which works in all themes.

### How to install manually

Create the file `~/.vim/plugins/spell.vim`. Add the same contents as
<https://github.com/webinstall/webi-installers/blob/master/vim-italics/italics.vim>.

That will look something like this:

```vim
" use underlines for italics
" (keeps the cursor visible while moving over italic text in all themes)
highlight htmlItalic gui=italic ctermfg=214
```

You'll then need to update `~/.vimrc` to source that plugin:

```vim
" Vim Italics: underlines for italics from webinstall.dev/vim-italics
source ~/.vim/plugins/italics.vim
```

### Troubleshooting

If you still can't see your cursor on italics, or things otherwise look wrong,
try moving the `source ~/.vim/plugins/italics.vim` closer to the top of your
config - above other things that may also be modifying the italics behavior.

#### Example

`~/.vimrc`:

```diff
+ " Vim Italics: underlines for italics from webinstall.dev/vim-italics
+ source ~/.vim/plugins/italics.vim

  " ALE: reasonable defaults from webinstall.dev/vim-ale
  source ~/.vim/plugins/ale.vim

- " Vim Italics: underlines for italics from webinstall.dev/vim-italics
- source ~/.vim/plugins/italics.vim
```

Or, in some cases, moving it closer to the bottom may help.
