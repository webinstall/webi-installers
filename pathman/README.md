---
title: Pathman
homepage: https://git.rootprojects.org/root/pathman
tagline: |
  Pathman: cross-platform PATH management for bash, zsh, fish, cmd.exe, and PowerShell.
---

## Updating `pathman`

```sh
webi pathman
```

## Cheat Sheet

Manages PATH on various OSes and shells

- Mac, Windows, Linux
- Bash, Zsh, Fish
- Command, Powershell

```sh
pathman help
```

### Usage

```sh
pathman add ~/.local/bin
```

```sh
pathman remove ~/.local/bin
```

Note: Even on Windows it is best to use Unix-style `/` paths and `~` for
`%USERPROFILE%`.

```sh
pathman list
```

```text
pathman-managed PATH entries:

	$HOME/.local/bin
	$HOME/.local/opt/go/bin
	$HOME/go/bin
	$HOME/.local/opt/node/bin

other PATH entries:

	/usr/local/bin
	/usr/bin
	/bin
	/usr/sbin
	/sbin
```
