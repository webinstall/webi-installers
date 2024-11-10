---
title: uuidv7
homepage: https://github.com/coolaj86/uuidv7
tagline: |
  uuidv7: generate UUID v7 strings, command line edition
---

To update or switch versions, run `webi uuidv7@stable`.

## Cheat Sheet

> `uuidv7` exists because _somebody_ was tired of searching "UUID v7 generator"
> just to get a test value for a little ditty now and then. Though, the time
> spent creating it will probably never be recouped...

```sh
uuidv7
```

```text
01928d73-d8ed-7211-a314-7081d763271d
```

## Table of Contents

- Files
- Generating Many `UUIDv7`s
- Roll Your Own UUID v7 Generator
- Understanding the UUID v7 spec
  - UUID v7, by the String
  - UUID v7, by the Byte

### Files

These are the files / directories that are created and/or modified with this
install:

```text
~/.config/envman/PATH.env
~/.local/bin/uuidv7
~/.local/opt/uuidv7/
```

### How to Generate Many v7 UUIDs at Once

```sh
uuidv7 ; uuidv7 ; uuidv7
```

```text
01928d74-3ff7-796f-8417-0fee6da50a5a
01928d74-3ff9-73f7-8ce1-71e741cfa56f
01928d74-3ffb-7e06-abe9-3fe20e5cb5f2
```

### How to Generate UPPER CASE (like `uuidgen`)

```sh
uuidv7 | tr '[:lower:]' '[:upper:]'
```

```text
01928D73-D8ED-7211-A314-7081D763271D
```

### How to Generate v4 UUIDs?

Use `uuidgen`.

```sh
uuidgen
uuidgen | tr '[:upper:]' '[:lower:]'
```

```text
84FA79E5-024E-4388-8D10-91618B93BE9D
84fa79e5-024e-4388-8d10-91618b93be9d
```

### How could I roll my own UUID v7 generator?

It's not that hard. There are examples in many languages here:

- https://github.com/coolaj86/uuidv7

See the simplified spec examples below.

### What's the UUID v7 spec, in simple terms?

See the explanation here:

- https://github.com/coolaj86/uuidv7

A snapshot of that is copied here, for convenience:

### UUID v7, by the Characters

There are 36 characters total: 32 hex (`0123456789abcdef`) + 4 dashes (`-`)

```text
  8 time    4 time    1v + 3ra   ½v + 3½rb    12 random b
019212d3  -  87f4   -   7d25   -   902e   -   b8d39fe07f08
```

- 8ch hex time high
- `-`
- 4ch hex time low
- `-`
- 4ch hex version + "random a"
  - 1ch hex version: `7`
  - 3ch hex "random a"
- `-`
- 4ch hex variant + "random b"
  - 1ch hex version: `8`, `9`, `a`, `b`
  - 3ch hex "random b"
- `-`
- 12ch hex randam a
  - 4ch hex random a
  - 8ch hex random a

### UUID v7, by the Bits

There are 128 bits total: \
48 time and 80 random, with 4 version and 2 variant bits substituted

```text
   48 time         4ver, 12ra   2var, 14rb        random b
019212d3-87f4    -    7d25    -    902e    -    b8d39fe07f08
```

- 48 bits of timestamp
  - 32-bit high (minutes to years)
  - 16-bit low (seconds & milliseconds)
- 16 bits of version + random
  - 4-bit version (`0b0111`)
  - 12-bit random
- 64-bits variant + random
  - 2-bit variant (`0b10`)
  - 62-bit random
