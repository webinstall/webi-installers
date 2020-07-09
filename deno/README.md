---
title: Deno
homepage: https://github.com/denoland/deno
tagline: |
  Deno: A secure runtime for JavaScript and TypeScript.
---

## Updating `deno`

```bash
webi deno@stable
```

Use the `@beta` tag for pre-releases, or `@x.y.z` for a specific version.

## Cheat Sheet

> Deno proves that lightning does strike twice. It's the ease of use of node,
> the intentional tooling of Go, and built in Rust.

### Hello World

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
