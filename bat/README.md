---
title: bat
homepage: https://github.com/sharkdp/bat
tagline: |
  bat: A cat(1) clone with syntax highlighting and Git integration.
---

To update or switch versions, run `webi bat@stable` (or `@v0.18`, `@beta`, etc).

## Cheat Sheet

> `bat` is pretty much what `cat` would be if it were developed today's in the
> world of Markdown, git, etc.

### How to run on Windows

On Windows you'll get an error like this:

> execution cannot proceed run because vcruntime140.dll was not found

You need to download and install the
[Microsoft Visual C++ Redistributable](https://support.microsoft.com/en-us/help/2977003/the-latest-supported-visual-c-downloads)

### How to alias as `cat`

Update your `.bashrc`, `.zshrc`, or `.profile`

```bash
alias cat="bat --style=plain"
```

For situations in which you must use `cat` exactly, remember that you can escape
the alias:

```bash
\cat foo
```

### How to change the default behavior

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
