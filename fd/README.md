---
title: fd
homepage: https://github.com/sharkdp/fd
tagline: |
  fd is a git-aware, simple, fast and user-friendly alternative to find.
---

To update or switch versions, run `webi fd@stable` (or `@v8.2`, `@beta`, etc).

## Cheat Sheet

![](https://github.com/sharkdp/fd/raw/master/doc/screencast.svg?sanitize=true)

> `fd` is a modern, git-aware, syntax-enabled alternative to `find` that handles
> unicode, respects `.gitignore`, and ignores hidden directories by default.

### Colorized Recursive List

```sh
fd
```

### Case-Insensitive Recursive Search

Anytime you use only lowercase letters, it's case-insensitive by default.

```sh
fd foo
```

### Case-Sensitive, Showing all ignored and hidden files

All `.` files and folders, and anything in `.gitignore` are ignored by default.

```sh
fd -s -I -H foo
```

### To show only JavaScript and Markdown files

Use `-e` as many times as there are extensions that you want to match.

```sh
fd -e md -e mkdn -e js -e mjs
```

### Other options are mostly similar to `find`

For options see:

```sh
fd --help
```
