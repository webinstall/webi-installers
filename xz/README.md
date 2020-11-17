---
title: XZ Utils
homepage: https://tukaani.org/xz/
tagline: |
  XZ Utils is free general-purpose data compression software with a high compression ratio.
---

### Updating `xz`

`webi xz@stable`

The Windows builds are the official builds. The Mac and Linux builds are from
[github.com/therootcompany/xz-static](https://github.com/therootcompany/xz-static).

## Cheat Sheet

`xz` and `unxz` are modern alternatives to `gzip` (and `gunzip`). They use LZMA2
(de)compression (like 7z), and is supported across many platforms, and by `tar`.

Here's the shortlist of options we've found most useful:

```txt
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

```bash
unxz -k example.xz
```

```bash
tar xvf example.tar.xz
```

### How to "Zip"

```bash
xz -k ./example
```

```bash
tar cvf example.tar.xz ./example
```
