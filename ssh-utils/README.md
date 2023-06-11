---
title: SSH Utils
homepage: https://webinstall.dev/ssh-utils
tagline: |
  SSH Utils: Because --help takes too long.
---

## Cheat Sheet

> SSH Utils includes shortcut commands for common tasks.

- [ssh-adduser](../ssh-adduser/)
- [ssh-authorize](../ssh-authorize/)
- [ssh-pubkey](../ssh-pubkey/)
- [ssh-setpass](../ssh-setpass/)
- [sshd-prohibit-password](../sshd-prohibit-password/)

**ssh-pubkey**:

`ssh-pubkey` will make sure you have an SSH key, and then print it to the screen
and place it in `~/Downloads`.

```sh
ssh-pubkey
```

```text
~/Downloads/id_rsa.johndoe.pub:

ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDTOhRnzDJNBNBXVCgkxkEaDM4IAp81MtE8fuqeQuFvq5gYLWoZND39N++bUvjMRCveWzZlQNxcLjXHlZA3mGj1b9aMImrvyoq8FJepe+RLEuptJe3md4EtTXo8VJuMXV0lJCcd9ct+eqJ0jH0ww4FDJXWMaFbiVwJBO0IaYevlwcf0QwH12FCARZUSwXfsIeCZNGxOPamIUCXumpQiAjTLGHFIDyWwLDCNPi8GyB3VmqsTNEvO/H8yY4VI7l9hpztE5W6LmGUfTMZrnsELryP5oRlo8W5oVFFS85Lb8bVfn43deGdlLGkwmcJuXzZfostSTHI5Mj7MWezPZyoSqFLl johndoe@MacBook-Air
```

**ssh-adduser**:

Many modern web programs (`npm` and `postgres`, for example) will not function
correctly if run as root. `ssh-adduser` adds user `app` with the same
**`~/.ssh/authorized_keys`** as the `root` user, with a long random password,
and gives `app` `sudo` privileges.

**sshd-prohibit-password**:

Enforces security for `/etc/ssh/sshd_config`

```diff
- #PasswordAuthentication yes
+ PasswordAuthentication no

- #PermitRootLogin yes
+ PermitRootLogin prohibit-password

  # macOS only
- UsePAM yes
+ UsePAM no
```

**ssh-authorize**:

Adds public ssh keys from a string, file, or url to `~/.ssh/authorized_keys` to
allow the owner(s) of the keys access to the system to which they're added.

Also performs various checks to prevent errors.

**ssh-setpass**:

`ssh-setpass` will ask you for your old passphrase (if any) and then for the new
one to reset it with.
