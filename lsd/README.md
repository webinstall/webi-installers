---
title: LSDeluxe
homepage: https://github.com/Peltoche/lsd
tagline: |
  LSDeluxe: next gen ls command
---

### Updating `lsd`

`webi lsd@stable`

Use the `@beta` tag for pre-releases.

## Cheat Sheet

![](https://raw.githubusercontent.com/Peltoche/lsd/assets/screen_lsd.png)

> `lsd` is a modern, cross-platform, drop-in replacement for `ls`. It does
> everything that you expect it to, plus modern extras that you can check out
> with `lsd --help`.

Note: You must install [the nerdfont](https://webinstall.dev/nerdfont) and
update the font in your Terminal for `lsd` to show icons.

Run `lsd` exactly as you would `ls`:

```bash
lsd
```

But wait, there's more, you can `tree` as well:

```bash
lsd --tree
```

### How to turn off icons and colors

If you just want the benefits of a cross-platform `ls` without having to install
nerdfont or needing a modern terminal, you've got options:

```bash
lsd --icon=never --color=never
```

Since that can be a little awkward to type over and over, you can use an alias:

```bash
alias lsd=lsd --icon=never --color=never
lsd
```

### How to alias as `ls`, `ll`, `la`, etc

Update your `.bashrc`, `.zshrc`, or `.profile`

```bash
alias ls="lsd -F"
alias la="lsd -AF"
alias ll="lsd -lAF"
alias lg="lsd -F --group-dirs=first"
```

For situations in which you must use `ls` exactly, remember that you can escape
the alias:

```bash
\ls -lAF
```

### How to alias as `tree`

Update your `.bashrc`, `.zshrc`, or `.profile`

```bash
alias tree="lsd -AF --tree"
```

And when you want to use GNU `tree`, just escape the alias:

```bash
\tree
```
