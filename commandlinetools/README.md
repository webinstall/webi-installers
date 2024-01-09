---
title: XCode Command Line Tools
homepage: https://webinstall.dev/commandlinetools
tagline: |
  The XCode Command Line Tools include git, swift, make, clang, and other developer tools
---

## Cheat Sheet

> The developer tools provided by Apple for macOS.

- git
- swift
- make
- clang
- etc

This is also part of [webi-essentials](../webi-essentials/).

## Table of Contents

- Files
- Manual Install
  - macOS
  - Linux
  - Alpine
  - Windows

### Files

These are the files / directories that are created and/or modified with this
install:

```sh
/Library/Developer/CommandLineTools/
```

### How to Install Manually

It's very easy to start the installer:

```sh
xcode-select --install
```

The trick is to also have a mechanism to know when it has finished:

```sh
while ! test -x /Library/Developer/CommandLineTools/usr/bin/git ||
    ! test -x /Library/Developer/CommandLineTools/usr/bin/make; do
    sleep 0.25
done

echo "Command Line Tools Installed"
```
