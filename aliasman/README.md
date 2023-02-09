---
title: aliasman
homepage: https://github.com/BeyondCodeBootcamp/aliasman
tagline: |
  aliasman: A cross-shell (POSIX-compliant) alias manager for bash, zsh, and fish
---

To update or switch versions, run `webi aliasman@stable` (or `@v1.0.0`, `@beta`,
etc).

### Files

These are the files / directories that are created and/or modified with this
install:

```text
~/.config/envman/PATH.env
~/.config/envman/alias.env
~/.local/bin/aliasman
```

## Cheat Sheet

> `aliasman` helps you love your *alias*es again! \
> Set 'em once, use 'em everywhere! \
> (and all in just one dotfile, for an on-the-go friendly config)

```sh
# aliasman <alias-name> <command-name> [args, pipes, redirs, etc]
aliasman ll 'lsd -lAhF'
```

Common aliases from around webi:

```sh
aliasman curl 'curlie'

alias diffy='diff -y --suppress-common-lines'

alias la='lsd -AF'
alias ll='lsd -lAhF'
alias ls='lsd -F'

alias tree='lsd -F --tree --group-dirs=last'

# random password generator
alias rnd='xxd -l24 -ps /dev/urandom'
```

### How to replace an alias

Just run the command again!

```sh
aliasman ll 'lsd -l'
aliasman ll 'lsd -lAhF'
```

### How to delete an alias

With `--delete`!

```sh
aliasman --delete ll
```

### How to see an alias

Just supply the name!

```sh
aliasman rnd
```

```text
alias rnd='xxd -l24 -ps /dev/urandom'
```
