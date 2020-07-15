---
title: fzf
homepage: https://github.com/junegunn/fzf-bin
tagline: |
  fzf is a general-purpose command-line fuzzy finder.
---

### Updating

```bash
webi fzf@stable
```

Use the `@beta` tag for pre-releases.

## Cheat Sheet

> It's an interactive Unix filter for command-line that can be used with any
> list; files, command history, processes, hostnames, bookmarks, git commits,
> logs, etc.

### Live filter search results

```bash
find . | fzf
```

### Live filter logs

```bash
sudo journalctl -u my-app-name  --since '2020-01-01' | fzf
```
