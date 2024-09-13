---
title: runzip
homepage: https://github.com/therootcompany/runzip
tagline: |
  runzip: a cross-platform unrar alternative... for unzipping .rar files
---

To update or switch versions, run `webi runzip@stable`.

### Files

These are the files / directories that are created and/or modified with this
install:

```text
~/.config/envman/PATH.env
~/.local/bin/runzip
```

## Cheat Sheet

> `runzip` is like `unrar`, but written in Go for security and wide
> compatibility.

```sh
# runzip <archive.rar> [./dst/]
runzip ./backup.rar .
```

```text
extracting to temporary path 'backup.tmp/'...
extracted to 'backup/'
```
