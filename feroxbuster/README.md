---
title: feroxbuster
homepage: https://github.com/epi052/feroxbuster
tagline: |
  feroxbuster: A tool designed to perform Forced Browsing.
---

To update or switch versions, run `webi feroxbuster@stable` (or `@v2`, `@beta`,
etc).

### Files

These are the files / directories that are created and/or modified with this
install:

```text
~/.config/feroxbuster/ferox-config.toml
~/.local/bin/feroxbuster
```

## Cheat Sheet

> `feroxbuster` is a tool designed for Forced Browsing. Forced browsing is an
> attack where the aim is to enumerate and access resources that are not
> referenced by the web application but are still accessible by an attacker.

To run feroxbuster:

```sh
feroxbuster -u [target]
```

### Include Headers

To run feroxbuster with custom headers:

```sh
feroxbuster -u [target] -H Accept:application/json "Authorization: Bearer {token}"
```

### Proxy Traffic Through Burp

To proxy traffic through Burp:

```sh
feroxbuster -u [target] --insecure --proxy http://127.0.0.1:8080
```
