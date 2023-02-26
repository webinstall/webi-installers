---
title: Dotenv Linter
homepage: https://dotenv-linter.github.io/
tagline: |
  dotenv-linter: ⚡️ Lightning-fast linter for .env files. Written in Rust 🦀
---

### Updating `dotenv-linter`

`webi dotenv-linter@stable`

Use the `@beta` tag for pre-releases.

#### Windows

On Windows you'll get an error like this:

> execution cannot proceed run because `vcruntime140.dll` was not found

You need to download and install the
[Microsoft Visual C++ Redistributable](https://support.microsoft.com/en-us/help/2977003/the-latest-supported-visual-c-downloads).

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

Use the `--fix` flag.

```sh
dotenv-linter --fix
```

Backup files in the format of `.env_0000000000` will be created by default. You
can use `--no-backup` to skip this.

### How to toggle linter rules

You can turn off certain linter checks with `--skip` options, for example:

```sh
dotenv-linter --skip QuoteCharacter --skip UnorderedKey
```

You can see the full list of linter rules with `dotenv-linter --show-checks`:

```text
DuplicatedKey
EndingBlankLine
ExtraBlankLine
IncorrectDelimiter
LeadingCharacter
KeyWithoutValue
LowercaseKey
QuoteCharacter
SpaceCharacter
TrailingWhitespace
UnorderedKey
```
