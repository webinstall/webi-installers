---
title: SSH Authorize
homepage: https://webinstall.dev/ssh-authorize
tagline: |
  Add to your SSH Authorized Keys from a string, file, or url.
---

### Files

These are the files / directories that are created and/or modified with this
install:

```text
~/.config/envman/PATH.env
~/.local/bin/ssh-authorize
~/.ssh/authorized_keys

# Windows
$Env:ProgramData\ssh\administrators_authorized_keys
```

## Cheat Sheet

> Does the tedious work of making sure your `.ssh/authorized_keys` exists with
> the proper permissions, and that only valid keys from a given string, file, or
> URL go into it!

Use `ssh-authorize` to add trusted public keys to allow others to login to your
servers / systems / local computers;

```sh
# ssh-authorize <ssh-pubkey-or-file-or-url> [comment]
ssh-authorize https://github.com/jonny.keys 'My GitHub Keys'
```

```text
USAGE

    ssh-authorize <ssh-pubkey-or-file-or-url> [comment]

EXAMPLES

    ssh-authorize https://github.com/you.keys 'My GH Keys'

    ssh-authorize ./id_rsa.you@example.co.pub

    ssh-authorize 'ssh-rsa AAAA...example.co'

LOCAL IDENTIFY FILES

    /home/app/.ssh/id_rsa.pub
```

### How to Add SSH Public Keys Manually

For the simplest case it seems almost silly to even have a utility for this:

```sh
mkdir -p ~/.ssh/
chmod 0700 ~/.ssh/

touch ~/.ssh/authorized_keys
chmod 0600 ~/.ssh/

curl https://github.com/me.keys >> ~/.ssh/authorized_keys
```

but... tedium, error checking... things are never as simple as they seem.

### How to use on Windows

You will need to run from an Elevated PowerShell, or use the
[Windows sudo](../sudo/).

### Why use ssh-authorize at all?

At first blush it seems easy enough to just add download or add files to
`~/.ssh/authorized_keys`, but there are complexities (especially on _Windows_).

This just adds a layer of convenience, and a few benefits:

- handles arbitrary files and URLs, failing bad key lines
- sets permissions correctly, even if they were incorrect \
  (which almost no one will to do successfully by hand on Windows on the first try)
- works `curl` (macOS, Ubuntu) or `wget` (Docker, Alpine)
- enforces `https`
