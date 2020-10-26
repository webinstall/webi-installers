---
title: Pandoc
homepage: https://github.com/jgm/pandoc
tagline: |
  Pandoc is a Haskell library for converting from one markup format to another.
---

## Updating `pandoc`

```bash
webi pandoc@stable
```

Use the `@beta` tag for pre-releases.

## Cheat Sheet

> Pandoc is a Haskell library for converting from one markup format to another, and a command-line tool that uses this library.

```bash
pandoc -o output.html input.txt
```

Specifying formats

```bash
pandoc -f markdown -t latex hello.txt
```

Documentation: https://pandoc.org/MANUAL.html
