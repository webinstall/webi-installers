---
title: HOL Guard
homepage: https://github.com/hashgraph-online/hol-guard
tagline: |
  HOL Guard: Inspect and control AI-agent actions
---

This installer provides the official standalone `hol-guard` CLI for glibc-based
Linux x86-64 using the upstream `x86_64-unknown-linux-gnu` release asset.
Check the selected release's system requirements before installing, since the
minimum supported glibc version can change between releases. macOS, Windows,
musl-based systems and other CPU architectures are not included.

To update or switch versions, run `webi hol-guard@stable`.

### Files

The installer creates or updates:

```text
~/.config/envman/PATH.env
~/.local/opt/hol-guard-v<version>/
~/.local/bin/hol-guard
```

## Cheat Sheet

Check the installed version and available commands:

```sh
hol-guard --version
hol-guard --help
```

Installing the CLI does not activate protection or change AI-tool hooks. Review
the [official documentation](https://github.com/hashgraph-online/hol-guard)
before choosing a setup or enforcement command.
