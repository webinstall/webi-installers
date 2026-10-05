---
title: sofka
homepage: https://github.com/nklmilojevic/sofka
tagline: |
  sofka: A Kubernetes TUI written in Rust.
---

To update or switch versions, run `webi sofka@stable` (or `@v0.29`, `@beta`,
etc).

### Files

These are the files that are created and/or modified with this installer:

```text
~/.config/envman/PATH.env
~/.local/bin/sofka
~/.local/opt/sofka-VERSION/bin/sofka
```

## Cheat Sheet

> `sofka` is a terminal UI for Kubernetes, inspired by k9s. It has Flux CD and
> Argo CD actions built in, and it explains why a resource is broken.

### How to start sofka

```sh
sofka
```

### How to use a specific context

```sh
sofka --context my-cluster
```

### How to see all options

```sh
sofka --help
```
