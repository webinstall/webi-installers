---
title: timeout
homepage: https://github.com/posix-utilities/timeout
tagline: |
  A POSIX.1-2024 timeout for macOS and systems that do not ship one yet.
---

To update or switch versions, run `webi timeout@stable` (or `@v1`, `@beta`,
etc).

### Files

These are the files that are created and/or modified with this installer:

```text
~/.config/envman/PATH.env
~/.local/bin/timeout
~/.local/opt/timeout-VERSION/bin/timeout
```

## Cheat Sheet

> `timeout` is a drop-in POSIX.1-2024 timeout for systems that do not ship one
yet.

### Run a command with a timeout

```sh
timeout 10s command [arguments...]
timeout -k 3s 10s command [arguments...]
```

### Check the installed version

```sh
timeout --version
```
