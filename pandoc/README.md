---
title: Pandoc
homepage: https://github.com/jgm/pandoc
tagline: |
  Pandoc is a Haskell library for converting from one markup format to another.
---

To update or switch versions, run `webi pandoc@stable` (or `@v2.14`, `@beta`,
etc).

## Cheat Sheet

> Pandoc is a Haskell library for converting from one markup format to another,
> and a command-line tool that uses this library.

```sh
pandoc -o output.html input.txt
```

Specifying formats

```sh
pandoc -f markdown -t latex hello.txt
```

Documentation: https://pandoc.org/MANUAL.html
