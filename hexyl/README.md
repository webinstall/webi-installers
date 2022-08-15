---
title: hexyl
homepage: https://github.com/sharkdp/hexyl
tagline: |
  hexyl is a simple hex viewer for the terminal.
---

To update or switch versions, run `webi hexyl@stable` (or `@v0.9`, `@beta`,
etc).

## Cheat Sheet

![](https://camo.githubusercontent.com/1f71ee7031e1962b23f21c8cc89cb837e1201238/68747470733a2f2f692e696d6775722e636f6d2f4d574f3975534c2e706e67)

> It uses a colored output to distinguish different categories of bytes (NULL
> bytes, printable ASCII characters, ASCII whitespace characters, other ASCII
> characters and non-ASCII).

`hexyl` is pretty self-explanatory.

If you know that you need a _hex viewer_, then you probably already know enough
to see why this is particularly useful, and can figure out how to use it.

```sh
echo "hello" > foo.bin
hexyl foo.bin
```

For options, such as `--length`, `--skip`, and `--offset`, see:

```sh
hexyl --help
```

### Convert hex to binary

If you have some hex (say from some server logs) that you'd like to encode back
to binary to view in hexyl, you can convert it with `xxd`:

```sh
echo '48656c6c6f210a' > foo.hex
xxd -r -p foo.hex foo.bin
```
