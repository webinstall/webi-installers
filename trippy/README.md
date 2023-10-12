---
title: Trippy
homepage: https://github.com/fujiapple852/trippy
tagline: |
  Trippy: A tool that combines the functionality of traceroute and ping designed for networking issue analysis.
---

To update or switch versions, run `webi trippy@stable` (or `@v2`, `@beta`, etc).

### Files

These are the files / directories that are created and/or modified with this
install:

```text
~/.config/trippy/config.toml
~/.local/bin/trippy
~/.local/opt/trippy-vX.X.X
```

## Cheat Sheet

> Trippy combines the functionality of traceroute and ping to assist in
> analyzing networking issues. It supports multiple protocols such as ICMP, UDP,
> and TCP, and is equipped with a Tui interface for detailed analysis.

To run Trippy:

```sh
trippy [options]
```

### Trace Using Multiple Protocols

To trace using ICMP:

```sh
trippy --protocol ICMP
```

### Customizable Tracing Options

To set packet size & payload pattern:

```sh
trippy --packet-size 64 --payload-pattern "pattern"
```

### Tui Interface

Launch Trippy with the Tui interface:

```sh
trippy --tui
```
