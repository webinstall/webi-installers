---
title: csilgen
homepage: https://github.com/catalystcommunity/csilgen
tagline: |
  csilgen: A code generator for CSIL schema files.
description:
  A CLI for CBOR Service Interface Language (CSIL) files. Validate a schema,
  check two versions for breaking changes, format and lint source files, and
  generate client and server code for many languages.
---

To update or switch versions, run `webi csilgen@stable` (or `@v0.2.6`, `@beta`,
etc).

### Supported platforms

`csilgen` publishes builds for these platforms:

- Linux x86_64
- Linux arm64
- macOS Apple Silicon (arm64)
- Windows x86_64

`csilgen` does not yet publish a macOS Intel (x86_64) build or a Windows arm64
build. The installer detects these platforms and stops with a message, instead
of failing partway through a download.

### Files

These are the files that are created and/or modified with this installer:

```text
~/.config/envman/PATH.env
~/.local/bin/csilgen
~/.local/opt/csilgen-VERSION/bin/csilgen
~/.csilgen/generators/csilgen_*_generator.wasm
~/Downloads/webi/csilgen-generators-VERSION.tar.gz
```

## Cheat Sheet

> `csilgen` reads a `.csil` schema file. It checks the file for errors. It turns
> the file into code for many languages. It also formats CSIL files, lints them,
> and checks two files for breaking changes.

CSIL is the schema language that [csilctl](/csilctl) reads at runtime. Write
your service and message definitions in a `.csil` file, then use `csilgen` to
turn that file into real code.

### How to check a CSIL file for errors

Use `validate` with `--input`. Give it the path to one file:

```sh
csilgen validate --input api.csil
```

Fix every error it reports before you generate code. `csilgen validate` also
resolves and checks any files that `api.csil` imports.

### How to generate code from a CSIL file

Use `generate`. Give it the input file, a target language, and an output
directory:

```sh
csilgen generate --input api.csil --target go --output ./generated/
```

`csilgen` creates the output directory if it does not exist. Run the command
again after you change the schema. It overwrites the old generated files.

### How to see the list of targets

`csilgen` installs 17 generator targets:

```text
c        csharp   dart     elixir   go       java     json
kotlin   ocaml    openapi  php      python   ruby     rust
swift    typescript        zig
```

Five of these targets also have narrower sub-targets, for when you only want
part of the generated code. Add `-client`, `-server`, or `-typesonly` to the
target name:

```sh
csilgen generate --input api.csil --target rust-client --output ./generated/
csilgen generate --input api.csil --target go-typesonly --output ./generated/
csilgen generate --input api.csil --target php-server --output ./generated/
```

This works for `rust`, `go`, `typescript`, `python`, and `php`.

### How to pin a generator per project

`csilgen` looks for generator modules in three places, in this order, and stops
at the first match:

1. `./target/wasm32-unknown-unknown/release` (a local `csilgen` build)
2. `./.generators` (a project-local override)
3. `~/.csilgen/generators` (the version this installer put in place)

Drop a generator `.wasm` file into a project's `.generators` folder to pin that
project to a different generator version than the one installed globally,
without touching your home directory:

```sh
mkdir -p .generators
cp ~/.csilgen/generators/csilgen_go_generator.wasm .generators/
```

Commit `.generators/` to the project's repository so every teammate and every CI
run generates the same code.

### How to skip the schema descriptor file

Every successful `generate` also writes a `<input-name>.csil-schema.cbor` file
next to the generated code. Add `--no-schema` to turn this off:

```sh
csilgen generate --input api.csil --target go --output ./generated/ --no-schema
```

### How to format and lint CSIL files

`format` and `lint` both take a directory, not a single file. Point them at the
folder that holds your `.csil` files:

```sh
csilgen format ./schemas/ --dry-run
csilgen format ./schemas/
csilgen lint ./schemas/
csilgen lint ./schemas/ --fix
```

Run `format` with `--dry-run` first to see which files would change. Run `lint`
before every commit; treat its exit code as a check, but do not worry about
every warning it prints — some warnings only flag a house style choice.

### How to check for breaking changes

Use `breaking` to compare an old and a new version of the same schema. Give the
old file as `--current` and the new file as `--new`:

```sh
csilgen breaking --current api-v1.csil --new api-v2.csil
```

Run this in CI on every pull request that touches a `.csil` file, before you
merge a change that a deployed client already depends on.

### How to see all options

```sh
csilgen --help
csilgen generate --help
csilgen validate --help
```
