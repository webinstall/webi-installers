---
title: TinyGo
homepage: https://tinygo.org
tagline: |
  TinyGo: The Power of Go, in Kilobytes.
---

To update or switch versions, run `webi tinygo@stable` (or `@v0.30`, `@beta`,
etc).

## Cheat Sheet

> TinyGo is an alternate, llvm-based compiler for Go with a much smaller and
> simpler runtime with a minimum size of _kilobytes_ - suitable for
> micro-controllers, embedded devices, and good old fashioned CLI utilities that
> don't need a high-performance garbage collector.

```sh
GOOS=linux GOARCH=arm64 \
    tinygo build -short -no-debug \
    -o hello-v1.0.0-linux-arm64
```

You may also want to install the Go IDE tooling:
[go-essentials](/go-essentials).

## Table of Contents

- Files
- Effective TinyGo
- Compatibility
- Gotchas

### Files

These are the files / directories that are created and/or modified with this
install:

```text
~/.config/envman/PATH.env
~/.local/opt/tinygo/
~/.local/opt/go/
~/go/
```

### Effective TinyGo

Core differences from Go's self-hosted compiler:

- optimizes for stack usage over heap usage
- avoids reflection
- simpler (but slower) garbage collection
- reimplements some of Go's standard library for performance

By following certain patterns, you can avoid forcing heap allocation and get
better memory usage and performance.

See:

- TinyGo: Heap Allocation:
  <https://tinygo.org/docs/concepts/compiler-internals/heap-allocation/>.
- TinyGo: A New Compiler:
  <https://tinygo.org/docs/concepts/faq/why-a-new-compiler/>

### Go Compatibility

Your _Go_, _TinyGo_, and dependency versions (particularly `golang.org/x`) will
need to be paired.

See the [Go Compatibility Matrix][go-compat]

[go-compat]: https://tinygo.org/docs/reference/go-compat-matrix/

### Gotchas

**Standard Library**

- avoid packages that rely heavily on reflection, like `encoding/json`

**Windows**:

- not all Windows syscalls are implemented

**macOS**:

- you may need to install a conflict-free version of `llvm` from
  [conflict-free brew](../brew/) to get small sizes when cross-compiling

See also:

- TinyGo: Language Support: <https://tinygo.org/docs/reference/lang-support/>
- TinyGo: Gotchas: <https://tinygo.org/docs/guides/tips-n-tricks/>
- TinyGo: Differences from Go:
  <https://tinygo.org/docs/concepts/compiler-internals/differences-from-go/>
