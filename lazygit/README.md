---
title: Lazygit
homepage: https://github.com/jesseduffield/lazygit
tagline: |
  simple terminal UI for git commands
---

To update or switch versions, run `webi lazygit@stable` (or `@v0.59`, etc).

### Files

```text
~/.config/envman/PATH.env
~/.local/bin/lazygit
```

## Cheat Sheet

lazygit is a simple terminal UI for git commands, written in Go. It provides an
interactive interface for common git operations like staging, committing,
branching, and more.

[Watch the official tutorial on YouTube](https://www.youtube.com/watch?v=CPLdltN7wgE)

To start in the current directory:

```sh
lazygit
```

### Common Keybindings

| Key     | Action               |
|---------|----------------------|
| `q`     | Quit                 |
| `Space` | Stage/unstage file   |
| `Enter` | Open file in editor  |
| `c`     | Commit changes       |
| `p`     | Push changes         |
| `P`     | Pull changes         |
| `b`     | Checkout branch      |
| `a`     | Amend last commit    |
| `s`     | Stash changes        |
| `?`     | Show all keybindings |
