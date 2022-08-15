---
title: Deno
homepage: https://github.com/denoland/deno
tagline: |
  Deno: A secure runtime for JavaScript and TypeScript.
---

To update or switch versions, run `webi deno@stable` (or `@v1.13`, `@beta`,
etc).

## Cheat Sheet

> Deno proves that lightning does strike twice. It's the ease of use of node,
> the intentional tooling of Go, and built in Rust.

### Hello World

The obligatory Hello World

```sh
deno run https://deno.land/std/examples/welcome.ts
```

Run a local file

```sh
deno run ./hello.ts
```

Enable [permissions](https://deno.land/manual/getting_started/permissions)

```sh
deno run --allow-read=./data,./public --allow-write=./data \
  --allow-net=example.com,example.net ./hello.ts
```

Format source code, recursively

```sh
deno fmt ./my-project
```
