---
title: SSH adduser
homepage: https://webinstall.dev/ssh-adduser
tagline: |
  SSH adduser: Because friends don't let friends login or run stuff as root
linux: true
description: |
  Many modern web programs (`npm` and `postgres`, for example) will not function correctly if run as root. `ssh-adduser` adds user `me` with the same **`~/.ssh/authorized_keys`** as the `root` user, with a long random password, and gives `me` `sudo` privileges.
---
