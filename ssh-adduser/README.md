---
title: SSH adduser
homepage: https://webinstall.dev/ssh-adduser
tagline: |
  SSH adduser: Because friends don't let friends login or run stuff as root
linux: true
---

## Cheat Sheet

> Many modern web programs (`npm` and `postgres`, for example) will not function
> correctly if run as root.

`ssh-adduser` will

1. add the user `app`
2. set a random, 32-character password (as a failsafe)
3. copy the `root` user's **`~/.ssh/authorized_keys`** (so the same users can
   still login)
4. give the `app` user `sudo` (admin) privileges
5. allow `app` to `sudo` without a password

How to create a new user named 'app':

```sh
# --disable-password prevents a password prompt
# --gecos "" skips the useless questions
adduser --disabled-password --gecos "" app
```

How to create a and set a random password:

```sh
# sets 'my_password' to 32 random hex characters (16 bytes)
my_password=$(openssl rand -hex 16)

# uses 'my_password' for to reset and confirm 'app's password
printf "$my_password"'\n'"$my_password" | passwd app
```

How to make the user 'app' a "sudo"er (an admin):

```sh
adduser app sudo
```

How to allow 'app' to run sudo commands without a password:

```sh
echo "app ALL=(ALL:ALL) NOPASSWD: ALL" | sudo tee /etc/sudoers.d/app
```

How to copy allowed keys from root to the new user:

```sh
mkdir -p /home/app/.ssh/
chmod 0700 /home/app/.ssh/

cat "$HOME/.ssh/authorized_keys" >> /home/app/.ssh/authorized_keys
chmod 0600 /home/app/.ssh/authorized_keys

chown -R app:app /home/app/.ssh/
```
