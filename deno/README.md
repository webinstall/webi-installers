---
title: Deno
homepage: https://github.com/denoland/deno
tagline: |
  Deno: A secure runtime for JavaScript and TypeScript.
description: |
  Deno proves that lightning does strike twice. It's the ease of use of node, the intentional tooling of Go, and built in Rust.
---

The obligatory Hello World

```bash
deno run https://deno.land/std/examples/welcome.ts
```

Run a local file

```bash
deno run ./hello.ts
```

Enable [permissions](https://deno.land/manual/getting_started/permissions)

```bash
deno run --allow-read=./data,./public --allow-write=./data \
  --allow-net=example.com,example.net ./hello.ts
```

Format source code, recursively

```bash
deno fmt ./my-project
```
