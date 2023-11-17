---
title: Webi Essentials
homepage: https://webinstall.dev/webi-essentials
tagline: |
  The Webi Essentials are curl, git, tar, wget, xz, zip, & webi shell integrations
---

### Cheat Sheet

> Even Webi needs a place to start.

This installs the tools that are commonly needed to download and unpack various
packages, using the native package manager.

**This requires root or `sudo`**

### Linux (Debian, Ubuntu)

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

### Alpine (Docker)

```sh
sudo apk add --no-cache \
    curl \
    git \
    tar \
    wget \
    xz \
    zip
```
