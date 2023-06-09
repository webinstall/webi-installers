---
title: SSH Prohibit Password
homepage: https://webinstall.dev/sshd-prohibit-password
tagline: |
  SSH Prohibit Password: Because friends don't let friends ssh with passwords
linux: true
---

## Cheat Sheet

> Will check if your system This will check if your Modern SSH deployments are
> key-only and don't allow root login. However, there's a lot of legacy systems
> out there.

`sshd-prohibit-password` will inspect `/etc/ssh/sshd_config` and

1. Enforce that `PasswordAuthentication` is `no`
2. Enforce that `PermitRootLogin` is `no` or `prohibit-password` \
   (or `without-password`, for older systems)
3. (macOS only) Enforce that `UsePAM` is `no`

This **will run automatically** and **uses `sudo`** to make changes.

### What's checked and changed?

```diff
- #PasswordAuthentication yes
+ PasswordAuthentication no

- #PermitRootLogin yes
+ PermitRootLogin prohibit-password

  # macOS only
- UsePAM yes
+ UsePAM no
```

### How to restart SSH?

```sh
# Ubuntu / Debian / RedHat
sudo systemctl restart sshd

# Alpine / Gentoo
sudo rc-service sshd restart

# macOS
sudo launchctl unload /System/Library/LaunchDaemons/ssh.plist
sudo launchctl load -w /System/Library/LaunchDaemons/ssh.plist

# others
killall sshd
```
