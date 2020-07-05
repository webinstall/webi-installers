---
title: bat
homepage: https://github.com/sharkdp/bat
tagline: |
  bat: A cat(1) clone with syntax highlighting and Git integration.
description: |
  `bat` is pretty much what `cat` would be if it were developed today in the world of Markdown, git, etc.
---

## How to alias as `cat`

Update your `.bashrc`, `.zshrc`, or `.profile`

```bash
alias cat="bat --style=plain"
```

## How to change the default behavior

Take a look at the config options:

```bash
bat --help
```

Check to see where your config file is:

```bash
echo 'N' | bat --generate-config-file
```

Edit the config file:

`~/.config/bat/config`:

```txt
# no numbers or headers, just highlighting and such
--style="plain"
```
