---
title: tlrc
homepage: https://github.com/tldr-pages/tlrc
tagline: |
  tlrc: A fast tldr client written in Rust.
---

To update or switch versions, run `webi tlrc@stable` (or `@v1.11`, `@beta`,
etc).

### Files

These are the files / directories that are created and/or modified with this
install:

```text
~/.config/envman/PATH.env
~/.local/bin/tlrc
~/.local/opt/tlrc/
```

## Cheat Sheet

> `tlrc` is a fast tldr client written in Rust. It provides community-maintained
> help pages for command-line tools with practical examples instead of lengthy
> man pages.

To get help for a command:

```sh
tlrc tar
```

### List all available pages

To see all available commands:

```sh
tlrc --list
```

### Update the cache

To update the local cache of tldr pages:

```sh
tlrc --update
```

### Search for commands

To search for commands containing a keyword:

```sh
tlrc --search "compress"
```

### Show examples for specific platform

To show examples for a specific platform:

```sh
tlrc --platform linux tar
```

### Random page

To display a random page:

```sh
tlrc --random
```
