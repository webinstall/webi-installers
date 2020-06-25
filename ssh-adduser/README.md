---
title: SSH adduser
homepage: https://webinstall.dev/ssh-adduser
tagline: |
  SSH adduser: Because friends don't let friends login or run stuff as root
linux: true
description: |
  Many modern web programs (`npm` and `postgres`, for example) will not function correctly if run as root.

  `ssh-adduser` will

    1. add the user `me`
    2. set a random, 32-character password (as a failsafe)
    3. copy the `root` user's **`~/.ssh/authorized_keys`** (so the same users can still login)
    4. give the `me` user `sudo` (admin) privileges
    5. allow `me` to `sudo` without a password
---

How to create a new user named 'me':

```bash
# --disable-password prevents a password prompt
# --gecos "" skips the useless questions
adduser --disabled-password --gecos "" me
```

How to create a and set a random password:

```bash
# sets 'my_password' to 32 random hex characters (16 bytes)
my_password=$(openssl rand -hex 16)

# uses 'my_password' for to reset and confirm 'me's password
printf "$my_password"'\n'"$my_password" | passwd me
```

How to make the user 'me' a "sudo"er (an admin):

```bash
adduser me sudo
```

How to allow 'me' to run sudo commands without a password:

```bash
echo "me ALL=(ALL:ALL) NOPASSWD: ALL" | sudo tee /etc/sudoers.d/me
```

How to copy allowed keys from root to the new user:

```bash
mkdir -p /home/me/.ssh/
chmod 0700 /home/me/.ssh/

cat "$HOME/.ssh/authorized_keys" >> /home/me/.ssh/authorized_keys
chmod 0600 /home/me/.ssh/authorized_keys

chown -R me:me /home/me/.ssh/
```
