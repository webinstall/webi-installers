---
title: Ripgrep
homepage: https://github.com/BurntSushi/ripgrep
tagline: |
  Ripgrep is a git and sourcecode-aware drop-in grep replacement.
---

## Updating `rg`

```bash
webi rg@stable
```

Use the `@beta` tag for pre-releases.

## Cheat Sheet

> Ripgrep (`rg`) is smart. It's like grep if grep were built for code. It
> respects `.gitignore` and `.ignore`, has all of the sensible options you
> want (colors, numbers, etc) turned on by default, is written in Rust, and
> typically outperforms grep in many use cases.

```bash
rg <search-term> # searches recursively, ignoring .git, node_modules, etc
```

```bash
rg 'function doStuff'
```

```bash
rg 'doStuff\(.*\)'
```
