---
title: Hugo Extended Edition
homepage: https://github.com/gohugoio/hugo
tagline: |
  Hugo, but with libsass and WebP support.
---

To update or switch versions, run `webi hugo-extended@stable` (or `@v0.118.2`,
`@beta`, etc).

### Files

These are the files / directories that are created and/or modified with this
install:

```text
~/.config/envman/PATH.env
~/.local/opt/hugo-extended/
~/.local/bin/hugo
```

## Cheat Sheet

> Hugo Extended Edition sacrifices some of the portability and memory-safety of
> Go in order to include libsass and WebP support.

- **libsass** (as opposed to ["dartsass"](../sass/) - a.k.a. [sass](../sass/))
- **WebP** encoding

If you DON'T need those, check out [Hugo](../hugo/) (Standard Edition).

### How to Switch Between Editions

If you've installed `hugo` and `hugo-extended` with Webi, you can switch easily:

```sh
webi hugo
```

```text
switched to 'hugo v0.118.2':
    /Users/aj/.local/bin/hugo => /Users/aj/.local/opt/hugo-v0.118.2/bin/hugo
```

```sh
webi hugo-extended
```

```text
switched to 'hugo v0.118.2':
    /home/me/.local/bin/hugo => /home/me/.local/opt/hugo-extended-v0.118.2/bin/hugo
```

### Why NOT Use Extended Edition?

The Standard Edition is written and compiled with Go, which means it's binaries:

- work on all OSes and architectures Go supports (musl, arm, BSD, etc)
- are more secure against attacks (Go is memory-safe, C languages are not)
- _slightly_ smaller file size (but... it doesn't really matter)

### [Hugo](../hugo/) Quick Start & Tips

See the [Hugo Cheat Sheet](../hugo/). See the [Hugo Cheat Sheet](../hugo/).
