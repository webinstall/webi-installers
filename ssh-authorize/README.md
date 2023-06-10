---
title: SSH Authorize
homepage: https://webinstall.dev/ssh-authorize
tagline: |
  Add to your SSH Authorized Keys from a string, file, or url.
---

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

### How to Add Manually

For the simplest case it seems almost silly to even have a utility for this:

```sh
mkdir -p ~/.ssh/
chmod 0700 ~/.ssh/

touch ~/.ssh/authorized_keys
chmod 0600 ~/.ssh/

curl https://github.com/me.keys >> ~/.ssh/authorized_keys
```

but... tedium, error checking... things are never as simple as they seem.

### But really, why?

- handles arbitrary files and URLs, failing bad key lines
- sets permissions correctly, even if they were incorrect
- works `curl` (macOS, Ubuntu) or `wget` (Docker, Alpine)
- enforces `https`
