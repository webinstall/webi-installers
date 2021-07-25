---
title: setcap-netbind
homepage: https://github.com/webinstall/webi-installers/setcap-netbind/README.md
tagline: |
  setcap-netbind: Give a binary the ability to bind to privileged ports.
---

setcap-netbind will grant the specified program the ability to listen on
privileged ports, such as 80 (http) and 443 (https) without root privileges or
sudo. It seeks out the specified binary in your path and reads down symlinks to
make usage as painless as possible.

## Cheat Sheet

```bash
sudo setcap-netbind node
```

This is the same as running the full command:

```bash
sudo setcap 'cap_net_bind_service=+ep' $(readlink -f $(which node))
```
