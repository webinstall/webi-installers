---
title: Archiver (arc)
homepage: https://github.com/mholt/archiver
tagline: |
  Arc is a cross-platform, multi-format archive utility.
---

To update or switch versions, run `webi arc@stable` (or `@v3.5`, `@beta`, etc).

### Files

```text
~/.config/envman/PATH.env
~/.local/opt/archiver/
```

## Cheat Sheet

> Archiver (`arc`) is a powerful and flexible library meets an elegant CLI in
> this generic replacement for several platform-specific or format-specific
> archive utilities.

Much like MacOS Finder and Windows Explorer, the default behavior of `arc` is to
create a top-level directory if one does not exist.

### List

```text
# arc ls <archive file>
arc ls   example.zip
```

### Unarchive (whole)

```text
# arc unarchive <archive file>
arc unarchive   example.zip
```

### Extract (partial)

```text
# arc extract <archive file> <archived path> <extracted path>
arc extract   example.zip    example/foo     ~/Downloads/foo
```

### Archive (recursive)

```text
# arc archive <archive file> <files or folders ...>
arc archive   example.zip    ./README.md ./bin ./src
```

### Compress (single file)

```text
# arc compress <single file> <format>
arc compress   ./example.tar xz
```

### Decompress (single file)

```text
# arc decompress <archive file>
arc decompress   ./example.tar.xz
```

## Supported extensions

These are the support compression formats, archive formats, and tar file and
other extensions.

| Compression | Archive  | Tar File | Bare Extension |
| ----------- | -------- | -------- | -------------- |
| -           | .tar     | -        | -              |
| xz          | .tar.xz  | .txz     | .xz            |
| gzip        | .tar.gz  | .tgz     | .gz            |
| bzip2       | .tar.bz2 | .tbz2    | .bz2           |
| brotli      | .tar.br  | .tbr     | .br            |
| lzma        | .tar.lz4 | .tlz4    | .lz4           |
| snappy      | .tar.sz  | .tsz     | .lsz           |
| zstd        | .tar.zst | -        | .zst           |
| ZIP         | .zip     | -        | -              |
| RAR         | .rar     | -        | -              |
