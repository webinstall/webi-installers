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

> `aliasman` helps you love your *alias*es again! 🥸 \
> Set 'em once, use 'em everywhere! \
> (and all in just one dotfile, for an on-the-go friendly config)

```sh
aliasman <alias-name> <command-name> [args, pipes, redirs, etc]
```

### What are Aliases?

An _alias_ is just shorthand for a shell function.

Take a long command like this:

```sh
git commit -m "feat: new feature"
```

And turn it into a short command, like this:

```sh
gc "feat: new feature"
```

(that would be `aliasman gc 'git commit -m'`)

### Imagine the possibilities!

1. What if you could quickly create a _command_, `ll`, \
   that does the work of `ls -lAhF`!?
2. Set an _alias_ to do just that!
   ```sh
   aliasman ll 'ls -lAhF'
   ```
3. Reload your alias config (or open a _new terminal_)
   ```sh
   source ~/.config/envman/alias.env
   ```
4. Use it!
   ```sh
   ll
   ```
   ```text
   drwxr-xr-x aj wheel 416 B  Thu Feb  9 02:08:39 2023 📂 .git/
   .rwxr-xr-x aj staff 6.2 KB Thu Feb  9 01:36:30 2023 💻 aliasman*
   .rw-r--r-- aj wheel  16 KB Wed Feb  8 21:51:06 2023 🔑 LICENSE
   .rw-r--r-- aj wheel 1.4 KB Thu Feb  9 01:47:13 2023 📄 README.md
   ```

### Common aliases

Use *alias*es to make other tools you find around webi even _more_ convenient
⚡️ (and powerful 💪).

```sh
aliasman curl 'curlie'

aliasman diffy 'diff -y --suppress-common-lines'

aliasman gc 'git commit -m'
aliasman gri 'git rebase -i'

aliasman la 'lsd -AF'
aliasman ll 'lsd -lAhF'
aliasman ls 'lsd -F'

aliasman rgi 'rg -i'

aliasman tree 'lsd -F --tree --group-dirs=last'

# random password generator
aliasman rnd 'xxd -l24 -ps /dev/urandom'
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
