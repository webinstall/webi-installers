---
title: Pathman
homepage: https://git.rootprojects.org/root/pathman
tagline: |
  Pathman: cross-platform PATH management for bash, zsh, fish, cmd.exe, and PowerShell.
---

To update or switch versions, run `webi pathman@stable` (or `@v0.5`, `@beta`,
etc).

## Cheat Sheet

Manages PATH on various OSes and shells

- Mac, Windows, Linux
- POSIX Shell, Bash, Zsh, Fish
- Command, Powershell

```sh
pathman add ~/bin/
```

<pre>
Saved changes to <code>~/.config/envman/PATH.env</code>

Copy, paste, and run the following command:

    <strong><em><code>PATH="$HOME/bin:$PATH"</code></em></strong>

(newly opened terminal windows will have the updated PATH)
</pre>

**Windows Users**: use POSIX-style `/` (for paths) and `~` (for
`%USERPROFILE%`) - they'll be adjusted automatically.

## Table of Contents

- Files
- Add, Remove, List, etc

### Files

These are the files / directories that are created and/or modified with this
install:

```text
~/.config/envman/PATH.env
~/.local/bin/pathman

# 'source ~/.config/envman/PATH.env' will be added to
~/.profile
~/.bashrc
~/.zshrc
~/.config/fish/config.fish
```

### Usage

```sh
pathman help
```

```sh
pathman add ~/.local/bin
```

```sh
pathman remove ~/.local/bin
```

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
