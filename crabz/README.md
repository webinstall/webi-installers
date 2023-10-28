---
title: Crabz
homepage: https://github.com/sstadick/crabz
tagline: |
  crabz: multi-threaded gzip (like pigz, but in Rust)
---

To update or switch versions, run `webi crabz@stable` (or `@0.8`, `@beta`, etc).

## Cheat Sheet

> `crabz` brings the power of multi-core compression to gzip and deflate. \
> (and a few other formats + other useful features)

gzip, faster.

```sh
crabz -I ./example.json
crabz -d -I ./example.json.gz
```

```text
Compressing (gzip) with 8 threads at compression level 6.
Decompressing (gzip) with 8 threads available.
```

## Table of Contents

- Files
- Tar
- Other Formats

### Files

These are the files/directories that are created and/or modified with this
install:

```text
~/.config/envman/PATH.env
~/.local/bin/crabz
```

#### How to Optimize

| Flag                          | Value | Comments                                   |
| ----------------------------- | ----- | ------------------------------------------ |
| `-l`, `--compression-level`   | 1-9   | higher is slower                           |
| `-p`, `--compression-threads` | 8     | set to the number of available cores       |
|                               |       | (but no more than 4 for decompression)     |
| `-P`, `--pin-at`              | 0     | pin to physical cores, starting at N       |
|                               |       | (so 4 threads starting at 0 is 0, 1, 2, 3) |

```sh
crabz -l 9 -p 8 -I ./example.tar

crabz -d -p 4 -I ./example.tar.gz
```

#### How to use with Tar

Tar and then compress:

```sh
tar cv ./example/ | crabz -o ./example.tar.gz
```

Or decompress and then untar:

```sh
crabz -d ./example.tar.gz | tar xv
```

#### How to use with other formats

`crabz` supports most of the _LZ77 with Huffman coding_ compression formats:

| Format           | Extension | Notes                                |
| ---------------- | --------- | ------------------------------------ |
| `gzip`           | `.gz`     | of GNU fame                          |
| [`bgzf`][bgzf]   | `.gz`     | supports random-access decompression |
| [`mgzip`][mgzip] | `.gz`     | of python fame                       |
| `zlib`           | `.zz`     | of PNG fame, also `.z`               |
| [`snap`][snap]   | `.sz`     | of LevelDB and MongoDB fame          |
| `deflate`        | `.gz`     | the O.G. LZ77                        |

```sh
crabz --format mgzip -I ./example.tar
```

```sh
# DO NOT decompress in-place
crabz --format mgzip -d ./example.tar.gz -o ./example.tar

# verify before removing the original
tar tf ./example.tar
```

⚠️ **Warnings**:

- DO NOT deflate in-place with non-standard formats: \
   Although `gunzip` will work correctly on files compressed with `mgzip` or
  `bgzf`, some combinations (ex: decompressing from `mgzip` with `bgzf`) could
  result in corruption!
- `tar xvf` and `gzip -l` may report incorrect information, even though `gunzip`
  will work

See also:

- https://dev.to/biellls/compression-clearing-the-confusion-on-zip-gzip-zlib-and-deflate-15g1

(p.s. `zip` isn't in the list because it's a container format like `tar`, not a
zip format)

[snap]: https://github.com/google/snappy/blob/main/format_description.txt
[bgzf]: https://samtools.github.io/hts-specs/SAMv1.pdf
[mgzip]: https://pypi.org/project/mgzip/
