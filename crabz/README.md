---

### Title: Crabz
Homepage: [Crabz on GitHub](https://github.com/sstadick/crabz)  
Tagline: |
  Crabz: A cross-platform, fast, compression and decompression tool written in Rust.

---

### How to Install or Switch Versions

To update or switch versions, you can use package managers like Homebrew, or
languages-specific package managers like Cargo. For example, to install using
Cargo, run:

```bash
cargo install crabz
```

### Files

These are the files/directories that are created and/or modified with this
install:

```text
~/.cargo/bin/crabz
~/.local/bin/crabz (if installed via Homebrew/Linuxbrew)
```

### Cheat Sheet

> `Crabz` is a fast, cross-platform compression and decompression tool. It
> supports multiple compression formats like Gzip, Zlib, Mgzip, BGZF, Raw
> Deflate, and Snap.

#### Basic Usage

To show help:

```sh
crabz -h
```

#### Compressing a File

By default, `crabz` uses gzip compression:

```sh
crabz [FILE]
```

#### Decompressing a File

To decompress a file, use the `-d` flag:

```sh
crabz -d [FILE]
```

#### Specifying Compression Level

To specify a compression level between 1 and 9:

```sh
crabz -l 9 [FILE]
```

#### Using Multiple Threads

To specify the number of threads:

```sh
crabz -p 4 [FILE]
```

### Add More Features

`Crabz` also allows you to pin threads to specific cores for performance
optimization, perform in-place compression/decompression, and choose from
various formats.

For pinning threads:

```sh
crabz -P 0 [FILE]
```

For in-place compression:

```sh
crabz -I [FILE]
```

To choose a format:

```sh
crabz -f zlib [FILE]
```
