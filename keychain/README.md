---
title: Funtoo:Keychain
homepage: https://www.funtoo.org/Funtoo:Keychain
tagline: |
  Keychain helps you to manage SSH and GPG keys in a convenient and secure manner.
---

To update or switch versions, run `webi keychain@stable` (or `@v2`, `@beta`,
etc).

### Files

These are the files / directories that are created and/or modified with this
install:

```text
~/.config/envman/PATH.env
~/.local/bin/keychain
~/.local/opt/keychain/
```

## Cheat Sheet

> `keychain` helps you to manage SSH and GPG keys in a convenient and secure
> manner. It acts as a frontend to ssh-agent and ssh-add, but allows you to
> easily have one long-running ssh-agent process per system, rather than the
> norm of one ssh-agent per login session.

### Quick start

The following assumes that you have an RSA key pair named `id_rsa`

Add the following to your `~/.bash_profile`

```sh
eval `keychain --eval id_rsa`
```

### Multiple keys

The following assumes that you have an RSA key pair named `id_rsa` and a GPG key
with ID `1A2B3C4D5E6F7890`

Add the following to your `~/.bash_profile`

```sh
eval `keychain --eval id_rsa 1A2B3C4D5E6F7890`
```

### Finding your gpg key id

```sh
gpg --list-secret-keys --keyid-format=long
```

will output something like

```
/home/your-user/.gnupg/pubring.kbx
---------------------------------
sec   ed25519/1A2B3C4D5E6F7890 2025-06-10 [SC]
      ABCDEF0123456789ABCDEF011A2B3C4D5E6F7890
uid                 [ultimate] John Doe <john.doe@example.com>
ssb   cv25519/9876543210ABCDEF 2025-06-10 [E]
```

In this example your GPG key id would be `1A2B3C4D5E6F7890`
