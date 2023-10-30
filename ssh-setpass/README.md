---
title: SSH setpass
homepage: https://webinstall.dev/ssh-setpass
tagline: |
  Set a new passphrase on your SSH Private Key.
linux: true
---

### Files

These are the files / directories that are created and/or modified with this
install:

```text
~/.config/envman/PATH.env
~/.local/bin/ssh-setpass
~/.ssh/id_rsa
```

## Cheat Sheet

> `ssh-setpass` will ask you for your old passphrase and then for the new one to
> reset it with.

```sh
ssh-setpass
```
