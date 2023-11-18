---
title: Webi Essentials
homepage: https://webinstall.dev/webi-essentials
tagline: |
  The Webi Essentials are curl, git, tar, wget, xz, zip, & webi shell integrations
---

## Cheat Sheet

> Even Webi needs a place to start.

This installs the tools that are commonly needed to download and unpack various
packages, using the native package manager.

This requires **root or `sudo`** for `apt` or `apk` on Linux.

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
# macOS
/Library/Developer/CommandLineTools/
/Library/Apple/usr/libexec/oah/libRosettaRuntime

# macOS & Windows
~/.local/bin/xz
~/.local/bin/unxz

# Windows
~/.local/opt/git/

# Linux
/usr/bin/git
```

### How to Install Manually

Most of these utilities are either built-in or provided by the native package
manager.

Webi makes it easy to automate across a wide variety of development systems, but
if you wanted to automate for a specific system, you could do so in a much
simpler way - because you don't have to worry about autodetection or fallbacks
😉.

So here's how to do that for each:

#### macOS

- Rosetta
  ```sh
  softwareupdate --install-rosetta --agree-to-license
  ```
- Command Line Developer Tools (incl. `git`)
  ```sh
  xcode-select --install
  ```
- `xz`
  ```sh
  curl https://webi.sh/xz | sh
  ```
  See <https://github.com/therootcompany/xz-static>.

#### Linux (Debian, Ubuntu)

```sh
sudo apt update
sudo apt install -y \
    curl \
    git \
    tar \
    wget \
    xz \
    zip
```

#### Alpine (Docker)

```sh
sudo apk add --no-cache \
    curl \
    git \
    tar \
    wget \
    xz \
    zip
```

#### Windows

`curl.exe` and BSD `tar.exe` are included as part of Windows 10+ - so there's no
needfor `wget` or `zip`.

- `git`

  ```sh
  curl.exe -A MS https://webi.ms/git | powershell
  ```

  See <https://github.com/git-for-windows/git/wiki/MinGit>

- `xz`
  ```sh
  curl https://webi.sh/xz | sh
  ```
  See <https://github.com/therootcompany/xz-static>.
