---
title: Homebrew
homepage: https://brew.sh
tagline: |
  Brew: The Missing Package Manager for macOS (and Linux).
---

To update or switch versions, use brew's built-in upgrade management, or our
handy update service script:

```sh
brew update
brew upgrade
brew-update-service-install # Webi helper script
```

### Files

These are the files / directories that are created and/or modified with this
install:

```text
~/.config/envman/PATH.env
~/.local/opt/brew/
~/.local/bin/brew-update-service-install
```

## Cheat Sheet

> Homebrew installs the stuff you need that Apple (or your Linux system) didn’t.

**Important**: This will install `brew` to `~/.local/opt/brew/`, NOT
`/usr/local`. The ability to install brew, without `sudo`, in your HOME
directory is a relatively new feature. If you do encounter a `brew install`
issue, [report it to brew](https://github.com/Homebrew/homebrew-core/issues).
way, report it to brew.

### How to install CLI packages

```sh
brew update
brew install node
```

### How to install GUI packages

```sh
brew update
brew cask install docker
```

### Where are things installed?

```sh
~/.local/opt/brew/
```

For reference, traditional `brew` installs here:

```sh
/usr/local/Cellar/
/opt/homebrew-cask/Caskroom/
```

### `brew` screwed up everything, now what?

Sometimes you're compelled against all reason to do something really stupid,
like `brew upgrade` or `brew update python`, and your whole system gets borked.

If you need to _uninstall_ and _reinstall_ local brew:

```sh
rm -rf ~/.local/opt/brew
webi brew
```

If you need to _uninstall_ global brew:

For _Mojave_, _Catalina_, _Big Sur_, and above:

```sh
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/uninstall.sh)"
```

For _High Sierra_ and below:

```sh
/bin/bash -c ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/uninstall)"
```
