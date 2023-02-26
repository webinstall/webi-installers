---
title: XZ Utils
homepage: https://tukaani.org/xz/
tagline: |
  XZ Utils is free general-purpose data compression software with a high compression ratio.
---

To update or switch versions, run `webi xz@stable` (or `@v5.2`, `@beta`, etc).

## Cheat Sheet

`xz` and `unxz` are modern alternatives to `gzip` (and `gunzip`). They use LZMA2
(de)compression (like 7z), and is supported across many platforms, and by `tar`.

Here's the shortlist of options we've found most useful:

```text
-z, --compress      force compression
-d, --decompress    force decompression
-l, --list          list information about .xz files

-k, --keep          keep (don't delete) input files
-c, --stdout        write to standard output and don't delete input files

-0 ... -9           (de)compression can take up to 4gb RAM at 7-9 (default 6)
-e, --extreme       try to improve compression ratio by using more CPU time
-T, --threads=N     use up to N threads; set to 0 to match CPU cores (default 1)
```

### How to "Unzip"

```sh
unxz -k example.xz
```

```sh
tar xvf example.tar.xz
```

### How to "Zip"

```sh
xz -k ./example
```

```sh
tar cvf example.tar.xz ./example
```
