---
title: fzf
homepage: https://github.com/junegunn/fzf
tagline: |
  fzf is a general-purpose command-line fuzzy finder.
---

To update or switch versions, run `webi fzf@stable` (or `@v0.23`, `@beta`, etc).

## Cheat Sheet

![](https://raw.githubusercontent.com/junegunn/i/master/fzf-preview.png)

> It's an interactive Unix filter for command-line that can be used with any
> list; files, command history, processes, hostnames, bookmarks, git commits,
> logs, etc.

### Live filter search results

```sh
find . | fzf
```

### Live filter logs

```sh
sudo journalctl -u my-app-name  --since '2020-01-01' | fzf
```

### Use space-delimited regular expressions to search

```text
^README | .md$ | .txt$
```
