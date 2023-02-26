---
title: VPS Utils
homepage: https://webinstall.dev/vps-utils
tagline: |
  VPS Utils make it easy to setup and manage a VPS
---

## Cheat Sheet

> VPS Utils includes shortcut commands for some common tasks, including
> `setcap-netbind`, 'vps-addswap', and 'myip'

**setcap-netbind**:

`setcap-netbind` will give the specified program the ability to listen on
privileged ports, such as 80 (http) and 443 (https) without `root` privileges or
`sudo`.

```sh
sudo setcap-netbind node
```

This is the same as running the full command:

```sh
setcap 'cap_net_bind_service=+ep' $(readlink -f $(which node))
```

**myip**:

Will output externally detected IPv4 and IPv6 addresses. See
<https://webinstall.dev/vps-myip>.

```sh
myip
```

```text
IPv4 (A)   : 136.36.196.101
IPv6 (AAAA): 2605:a601:a919:9800:f8be:f2c4:9ad7:9763
```

**vps-addswap**:

Adds and activates permanent swap in `/var/swapfile`. See
<https://webinstall.dev/vps-addswap>.

```sh
vps-addswap
```
