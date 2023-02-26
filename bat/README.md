---
title: bat
homepage: https://github.com/sharkdp/bat
tagline: |
  bat: A cat(1) clone with syntax highlighting and Git integration.
---

To update or switch versions, run `webi bat@stable` (or `@v0.18`, `@beta`, etc).

### Files

```text
~/.config/envman/PATH.env
~/.config/bat/config
~/.local/opt/bat/
```

## Cheat Sheet

> `bat` is pretty much what `cat` would be if it were developed today's in the
> world of Markdown, git, etc.

### How to run on Windows

On Windows you'll get an error like this:

> execution cannot proceed run because vcruntime140.dll was not found

You need to download and install the
[Microsoft Visual C++ Redistributable](https://support.microsoft.com/en-us/help/2977003/the-latest-supported-visual-c-downloads)

### How to alias as `cat`

Use [aliasman](/aliasman):

```sh
aliasman cat 'bat --style=plain'
alias cat='bat --style=plain'
```

Or place this in `~/.config/envman/alias.env` and manually update your
`.bashrc`, `.zshrc`, `.profile`, and/or `~/.config/fish/config.fish` to source
it.

```sh
alias cat="bat --style=plain"
```

For situations in which you must use `cat` exactly, remember that you can escape
the alias:

```sh
\cat foo
```

### How to change the default behavior

Take a look at the config options:

```sh
bat --help
```

Check to see where your config file is:

```sh
echo 'N' | bat --generate-config-file
```

Edit the config file:

`~/.config/bat/config`:

```text
# no numbers or headers, just highlighting and such
--style="plain"
```
