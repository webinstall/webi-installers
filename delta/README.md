---
title: delta
homepage: https://github.com/dandavison/delta
tagline: |
  delta: A syntax-highlighting pager for git and diff output
---

To update or switch versions, run `webi delta` (or `@0.9.1`, `@0.9.0`,
etc).

## Cheat Sheet

Install delta and add this to your `~/.gitconfig`:

```gitconfig
[pager]
    diff = delta
    show = delta
    log = delta
    blame = delta
    reflog = delta

[interactive]
    diffFilter = delta --color-only
```

Make sure to check out the helpful [ReadMe](https://github.com/dandavison/delta/blob/master/README.md)
