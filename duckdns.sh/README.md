---
title: DuckDNS.sh
homepage: https://github.com/BeyondCodeBootcamp/DuckDNS.sh
tagline: |
  DuckDNS.sh: Dynamic DNS updater for https://duckdns.org. Works on all POSIX*ish* systems (Mac, Linux, Docker, BSD, etc).
---

To update or switch versions, run `webi duckdns.sh@stable` (or `@v1.0.3`,
`@beta`, etc).

### Files

These are the files / directories that are created and/or modified with this
install:

```text
~/.config/envman/PATH.env
~/.local/bin/duckdns.sh
~/.config/duckdns.sh/
```

## Cheat Sheet

> DuckDNS.sh (`duckdns.sh`) is the best Dynamic DNS client to date. Not only
> does it have some nice sub commands and work on all Posix systems, but it can
> also register itself with your system launcher - `systemd` on Linux and
> `launchctl` on macOS.

Paste your token from [duckdns.org](https://duckdns.org) to start.

```sh
# duckdns.sh auth <subdomain>
# duckdns.sh auth foobar # do NOT include '.duckdns.org'
```

Set to launch on login (Mac) or on boot (Linux)

```sh
# duckdns.sh enable <subdomain>
duckdns.sh enable foobar
```

### Usage

Use `-v` to filter out all matches so that only non-matches are left.

```sh
USAGE
    duckdns.sh <subcommand> [arguments...]

SUBCOMMANDS
    myip                         - show this device's ip(s)
    ip <subdomain>               - show subdomain's ip(s)

    list                         - show subdomains
    auth <subdomain>             - add Duck DNS token
    update <subdomain>           - update subdomain to device ip
    set <subdomain> <ip> [ipv6]  - set ipv4 and/or ipv6 explicitly
    clear <subdomain>            - unset ip(s)
    run <subdomain>              - check ip and update every 5m
    enable <subdomain>           - enable on boot (Linux) or login (macOS)
    disable <subdomain>          - disable on boot or login

    help                         - show this menu
    version                      - show version and exit
```

### How to check your current IP address

```sh
duckdns.sh myip
```

This is the same as

```sh
curl -fsSL 'https://api.ipify.org?format=text'
curl -fsSL 'https://api64.ipify.org?format=text'
```

### How to check your domain's current DNS records

```sh
duckdns.sh ip foobar
```

This is the same as

```sh
dig +short A foobar.duckdns.org
dig +short AAAA foobar.duckdns.org
```

### How to manually set your domain's DNS records

```sh
duckdns.sh set foobar 127.0.0.1 ::1
```
