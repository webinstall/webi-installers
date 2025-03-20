---
title: fish
homepage: https://github.com/fish-shell/fish-shell
tagline: |
  fish is a smart and user-friendly command line shell for Linux, macOS, and the rest of the family.
---

To update or switch versions, run `webi fish@stable` (or `@v3.3`, `@beta`, etc).

## Cheat Sheet

> Finally, a command line shell for the 90s!
>
> fish includes features like syntax highlighting, autosuggest-as-you-type, and
> fancy tab completions that just work, with no configuration required.

!["fish features"](https://i.imgur.com/WVCyf5N.png)

`fish` is an _excellent_ command line shell for day-to-day file browsing and
running commands (the _BEST_, in fact).

However, it is **NOT** compatible with `bash` so you should still write and run
your scripts with bash.

This also covers how to

- Run bash scripts with bash
- Set vim to keep using bash
- Set fish as the default shell in **Linux**
- Set abbreviations for commands
- Set the default shell back to `bash`

### How to run bash scripts from fish

A bash script should have a "bash shebang" (`#!/bin/bash`) as the first line of
the file:

```sh
#!/bin/bash

echo "Who am I? I'm $(id -u -n)."
```

You can also run bash explicitly:

```sh
bash ./some-script.sh
```

### How to set preferences

To tweak with preferences:

```sh
fish_config
```

This will open up a html page to tweak fish to your liking!

### How to set vim to keep using bash

The first line of your `.vimrc` should always be `set shell=/bin/bash`.

`~/.vimrc`:

```vim
set shell=/bin/bash
```

### How to make fish the default shell on Linux

This requires editing a protected system file, `/etc/shells`. It is better to
use the Terminal-specific methods.

First, `fish` must be installed and in the `PATH`.

```sh
# if you don't see a file path as output, fish is not in the path
command -v fish
```

Second, fish must be in the system-approved list of shells in `/etc/shells`:

```sh
#!/bin/sh

if ! grep $(command -v fish) /etc/shells > /dev/null; then
    sudo sh -c "echo '$(command -v fish)' >> /etc/shells";
    echo "added '$(command -v fish)' to /etc/shells"
fi
```

You should use `chsh` to change your shell:

```sh
#!/bin/sh

sudo chsh -s "$(command -v fish)" "$(id -u -n)"
```

If vim uses `fish` instead of `bash`, annoying errors will happen.

### How to switch to fish

You can simply type `fish` and hit enter to start using fish from any other
shell.

You can also set is as the default for a particular Terminal, or for your user.

### How to set abbreviations

You can set cool abbreviations to your favorite commands in fish!

```sh
abbr -a <abbr-name> '<command-name>'

#abbr -a gs 'git status'
```

### How to set the default shell back to bash

See the instructions above for "How to make fish the default shell in _X_", but
use `/bin/bash` as the path instead of `$HOME/.local/bin/fish`.
