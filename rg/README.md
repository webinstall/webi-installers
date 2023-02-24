---
title: Ripgrep
homepage: https://github.com/BurntSushi/ripgrep
tagline: |
  Ripgrep is a git and sourcecode-aware drop-in grep replacement.
---

To update or switch versions, run `webi rg@stable` (or `@v13.0`, `@beta`, etc).

### Files

```text
~/.config/envman/PATH.env
~/.local/opt/rg/
~/.local/bin/rg
~/.ripgreprc
```

## Cheat Sheet

> Ripgrep (`rg`) is smart. It's like grep if grep were built for code. It
> respects `.gitignore` and `.ignore`, has all of the sensible options you want
> (colors, numbers, etc) turned on by default, is written in Rust, and typically
> outperforms grep in many use cases.

```sh
rg <search-term> # searches recursively, ignoring .git, node_modules, etc
```

```sh
rg 'function doStuff'
```

```sh
rg 'doStuff\(.*\)'
```

### Inverse Search

Use `-v` to filter out all matches so that only non-matches are left.

```sh
rg 'bar' | rg -v 'foobar'
```

### Disable Smart Filtering

By default `rg` respects `.gitignore`, `.ignore`, `.git/info/exclude` and
ignores many types of hidden files, dot files, etc.

You can use `-uu` to set all of the `--no-ignore-*` options and others.

```sh
rg -uu 'SECRET='
```
