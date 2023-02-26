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
- Set fish as the default shell in various Terminals
  - Terminal.app
  - iTerm2
  - Hyper
  - Alacritty
- Find fish's config files
- Set the default shell back to `bash`

### How to run bash scripts from fish

A bash script should have a "bash shebang" (`#!/bin/bash`) as the first line of
the file:

```sh
#!/bin/bash

echo "Who am I? I'm $(whoami)."
```

You can also run bash explicitly:

```sh
bash ./some-script.sh
```

### How to set the fish Color Scheme

You may like to have your `fish` theme match your Terminal or iTerm2 theme (such
as _Solarized_, _Dracula_, or _Tomorrow Night_).

```sh
fish_config colors
```

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

sudo chsh -s "$(command -v fish)" "$(whoami)"
```

If vim uses `fish` instead of `bash`, annoying errors will happen.

### How to switch to fish

You can simply type `fish` and hit enter to start using fish from any other
shell.

You can also set is as the default for a particular Terminal, or for your user.

### How to set fish as the Terminal.app shell

Find out where `fish` is:

```sh
command -v fish
```

Then update the Terminal preferences:

```text
Terminal > Preferences > General > Shells open with:
/Users/YOUR_USER/.local/bin/fish
```

![Terminal.app preferences](https://i.imgur.com/bulS4Vv.png)

Or, you can quit Terminal and change the preferences from the command line:

```sh
#!/bin/sh

defaults write com.apple.Terminal "Shell" -string "$HOME/.local/bin/fish"
```

### How to set fish as the iTerm2 shell

Find out where `fish` is:

```sh
command -v fish
```

Then update iTerm2 preferences:

```
iTerm2 > Preferences > Profiles > General > Command >
Custom Shell: /Users/YOUR_USER/.local/bin/fish
```

![iTerm2 Preferences](https://i.imgur.com/VtBUzVH.png)

Or, you can quit iTerm2 and change the preferences from the command line:

```sh
#!/bin/sh

/usr/libexec/PlistBuddy -c "SET ':New Bookmarks:0:Custom Command' 'Custom Shell'" \
    ~/Library/Preferences/com.googlecode.iterm2.plist

/usr/libexec/PlistBuddy -c "SET ':New Bookmarks:0:Command' 'Custom Shell' '$HOME/.local/bin/fish'" \
    ~/Library/Preferences/com.googlecode.iterm2.plist
```

### How to set fish as the Hyper shell

Hyper is configured with JavaScript.

`~/.hyper.js`:

```js
module.exports = {
  config: {
    // ...
    shell: process.env.HOME + '/.local/bin/fish',
  },
};
```

### How to set fish as the Alacritty shell

`~/.config/alacritty/alacritty.yml` should contain the shell config:

```yml
shell:
  program: /Users/YOUR_USER/.local/bin/fish
  args:
    - --login
```

If you don't yet have an alacritty config, this will do:

```sh
#!/bin/sh

mkdir -p ~/.config/alacritty

cat << EOF >> ~/.config/alacritty/alacritty.yml:
shell:
  program: $HOME/.local/bin/fish
  args:
    - --login
EOF
```

The default `alacritty.yml` is included as an _asset_ with each
[Github release](https://github.com/alacritty/alacritty/releases).

### Where is the fish config?

Fish will be installed to the standard user location:

```sh
~/.local/opt/fish/
```

It's config will also go in the standard user location:

```sh
~/.config/fish/config.fish
```

### How to set the default shell back to bash

See the instructions above for "How to make fish the default shell in _X_", but
use `/bin/bash` as the path instead of `$HOME/.local/bin/fish`.
