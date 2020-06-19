---
title: Adduser
homepage: https://webinstall.dev/adduser
tagline: |
  Because friends don't let friends run as root
linux: true
description: |
  Adds user `bob` with the same **`~/.ssh/authorized_keys`** as the root user, exiting early if run by a non-root user.
---

Check that `bob` exists

```bash
ls /home/
```
