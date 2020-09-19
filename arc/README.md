---
title: Archiver (arc)
homepage: https://github.com/mholt/archiver
tagline: |
  Arc is a cross-platform, multi-format archive utility.
---

## Updating `arc`

`webi arc@stable`

Use the `@beta` tag for pre-releases.

## Cheat Sheet

> Archiver (`arc`) is a powerful and flexible library meets an elegant CLI in
> this generic replacement for several platform-specific or format-specific
> archive utilities.

Much like MacOS Finder and Windows Explorer, the default behavior of `arc` is to
create a top-level directory if one does not exist.

### List

```txt
# arc ls <archive file>
arc ls   example.zip
```

### Unarchive (whole)

```txt
# arc unarchive <archive file>
arc unarchive   example.zip
```

### Extract (partial)

```txt
# arc extract <archive file> <archived path> <extracted path>
arc extract   example.zip    example/foo     ~/Downloads/foo
```

### Archive (recursive)

```txt
# arc archive <archive file> <files or folders ...>
arc archive   example.zip    ./README.md ./bin ./src
```

### Compress (single file)

```txt
# arc compress <single file> <format>
arc compress   ./example.tar xz
```

### Decompress (single file)

```txt
# arc decompress <archive file>
arc decompress   ./example.tar.xz
```

## Supported extensions

| format | packaged        | raw compressed |
| ------ | --------------- | -------------- |
| RAR    | .rar            | -              |
| -      | .tar            | -              |
| brotli | .tar.br, .tbr   | .br            |
| gzip   | .tar.gz, .tgz   | .gz            |
| bzip2  | .tar.bz2, .tbz2 | .bz2           |
| xz     | .tar.xz, .txz   | .xz            |
| lzma   | .tar.lz4, .tlz4 | .lz4           |
| snappy | .tar.sz, .tsz   | .lsz           |
| zstd   | .tar.zst        | .zst           |
| ZIP    | .zip            | -              |
