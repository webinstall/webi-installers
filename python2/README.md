---
title: Python 2 (via pyenv)
homepage: https://webinstall.dev/pyenv
tagline: |
  Python 2 is the legacy version of Python.
---

To update or switch versions, run `pyenv install -v 2` (or `2.6`, etc).

### How to Install python2 on macOS

Make sure that you already have Xcode tools installed:

```sh
xcode-select --install
```

You may also need to install Xcode proper from the App Store.

### How to Install python2 on Linux

Make sure that you already have the necessary build tools installed:

```sh
# required
sudo apt update
sudo apt install -y build-essential zlib1g-dev libssl-dev

# recommended
sudo apt install -y libreadline-dev libbz2-dev libsqlite3-dev
```

### Files

These are the files / directories that are created and/or modified with this
install:

```text
~/.bashrc (or your shell's equivalent)
~/.config/envman/PATH.env
~/.pyenv
```

## Cheat Sheet

![](https://github.com/ewjoachim/zen-of-python/raw/master/zen_web.png)

Unless you know you need Python 2 for a specific purpose, you should probably
use [Python 3](/python) instead.

For more info see these cheat sheets:

- [Python 3](/python)
- [pyenv](/pyenv)
