---
title: Homebrew
homepage: https://brew.sh
tagline: |
  Brew: The Missing Package Manager for macOS (and Linux).
---

## Updating `brew`

`brew` has its own built-in upgrade management.

```bash
brew update
brew upgrade
```

## Cheat Sheet

> Homebrew installs the stuff you need that Apple (or your Linux system) didn’t.

### How to install CLI packages

```bash
brew update
brew install node
```

### How to install GUI packages

```bash
brew update
brew cask install docker
```

### Where are things installed?

```bash
/usr/local/Cellar/
/opt/homebrew-cask/Caskroom/
```

### `brew` screwed up everything, now what?

Sometimes you're compelled against all reason to do something really stupid,
like `brew upgrade` or `brew update python`, and your whole system gets borked.

For _Mojave_, _Catalina_, _Big Sur_, and above:

```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/uninstall.sh)"
```

For _High Sierra_ and below:

```bash
/bin/bash -c ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/uninstall)"
```
