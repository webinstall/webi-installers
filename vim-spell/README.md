---
title: vim-spell
homepage: https://webinstall.dev/vim-spell
tagline: |
  vim spell is Vim's built-in spellcheck
---

To update (replacing the current version) run `webi vim-spell`.

### Files

These are the files / directories that are created and/or modified with this
install:

```text
~/.vimrc
~/.vim/plugins/spell.vim
```

## Cheat Sheet

Vim has a built-in spell checker. It is turned off by default and when turned on
will do whole-word highlighting - which does not look good in any of the themes
a I use.

This vim-spell plugin turns on the spell checker and sets it to use underline
rather than background coloring.

### How to add new words

The vim command to add words to your user's dictionary is `:spell <word>`. For
example:

```vim
:spell JSON
:spell HTML
```

### How to remove words

You can remove a word from your custom dictionary with `:spellundo <word>`, like
so:

```vim
:spellundo referer
```

You can blacklist word (mark it as an incorrect spelling) with
`:spellwrong <word>`, like this:

```vim
:spellwrong writeable

" use X11/HTML-defined 'gray', not the proper English 'grey'
:spellwrong grey
```

This is particularly useful if you want to make sure that you're consintent in
spelling words that have multiple spellings.

### Where are the custom files?

Your user-specific spell files in in `~/.vim/spell`. One is in binary form and
the other in text form, likely:

- `~/.vim/spell/en.utf-8.add`
- `~/.vim/spell/en.utf-8.add.spl`

### How to install manually

Create the file `~/.vim/plugins/spell.vim`. Add the same contents as
<https://github.com/webinstall/webi-installers/blob/master/vim-spell/spell.vim>.

That will look something like this:

```vim
" turn on spellcheck
set spell

" set spellcheck highlight to underline
hi clear SpellBad
hi SpellBad cterm=underline
```

You'll then need to update `~/.vimrc` to source that plugin:

```vim
" Spell Check: reasonable defaults from webinstall.dev/vim-spell
source ~/.vim/plugins/spell.vim
```
