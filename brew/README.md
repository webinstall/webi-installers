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
