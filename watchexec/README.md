---
title: watchexec
homepage: https://github.com/watchexec/watchexec
tagline: |
  watchexec is a simple, standalone tool that watches a path and runs a command whenever it detects modifications.
---

### Updating `watchexec`

`webi watchexec@stable`

Use the `@beta` tag for pre-releases.

## Cheat Sheet

Watch all JavaScript, CSS and HTML files in the current directory and all
subdirectories for changes, running `make` when a change is detected:

```bash
watchexec --exts js,css,html make
```

Call `make test` when any file changes in this directory/subdirectory, except
for everything below `target`:

```bash
watchexec -i target make test
```

Call `ls -la` when any file changes in this directory/subdirectory:

```bash
watchexec -- ls -la
```
