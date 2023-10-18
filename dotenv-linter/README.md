---
title: Dotenv Linter
homepage: https://dotenv-linter.github.io/
tagline: |
  dotenv-linter: ⚡️ Lightning-fast linter for .env files. Written in Rust 🦀
---

To update or switch versions, run `webi dotenv-linter@stable` (or `@v3.3`,
`@beta`, etc).

### Files

These are the files / directories that are created and/or modified with this
install:

```text
~/.config/envman/PATH.env
~/.local/bin/dotenv-linter
```

**Windows Users**

```text
\Windows\System32\vcruntime140.dll
```

This will also attempt to install the
[Microsoft Visual C++ Redistributable](/vcruntime) via `webi vcruntime`. If it
fails and you get the error _`vcruntime140.dll` was not found_, you'll need to
[install it manually](https://learn.microsoft.com/en-US/cpp/windows/latest-supported-vc-redist?view=msvc-170).

## Cheat Sheet

> Dotenv Linter is a lightning-fast check for your `.env` files. It can rapidly
> detect and automatically fix issues.

By default, `dotenv-linter` checks all `.env` files in the current directory:

```sh
dotenv-linter
```

This is the same as the default behavior:

```sh
dotenv-linter .env .env.*
```

To lint .env files recursively, use `-r`:

```sh
dotenv-linter -r
```

For the complete usage, see the official
[Dotenv Linter Usage Guide](https://dotenv-linter.github.io/#/usage).

### How to automatically fix errors

Use the `fix` subcommand.

```sh
dotenv-linter fix
```

Backup files in the format of `.env_0000000000` will be created by default. You
can use `--no-backup` to skip this.

### How to compare two files

Use the `compare` subcommand

```sh
dotenv-linter compare .env1 .env2
```

### How to toggle linter rules

You can turn off certain linter checks with `--skip` options, for example:

```sh
dotenv-linter --skip QuoteCharacter --skip UnorderedKey
```

You can see the full list of linter rules with `dotenv-linter list`:

```text
DuplicatedKey
EndingBlankLine
ExtraBlankLine
IncorrectDelimiter
KeyWithoutValue
LeadingCharacter
LowercaseKey
QuoteCharacter
SpaceCharacter
SubstitutionKey
TrailingWhitespace
UnorderedKey
ValueWithoutQuotes
```
