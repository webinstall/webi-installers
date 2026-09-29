---
title: csilctl
homepage: https://github.com/catalystcommunity/csilctl
tagline: |
  csilctl: A curl-like CLI for sending CSIL messages.
description:
  A command-line client for CSIL services. Read a .csil source file to list its
  messages and types, then send a message to a host and see the response.
---

To update or switch versions, run `webi csilctl@stable` (or `@v0.2.1`, `@beta`,
etc).

### Supported platforms

`csilctl` publishes builds for these platforms:

- Linux x86_64
- Linux arm64
- macOS Apple Silicon (arm64)
- Windows x86_64

`csilctl` does not yet publish a macOS Intel (x86_64) build or a Windows arm64
build. The installer detects these platforms and stops with a message, instead
of failing partway through a download.

### Files

These are the files that are created and/or modified with this installer:

```text
~/.config/envman/PATH.env
~/.local/bin/csilctl
~/.local/opt/csilctl-VERSION/bin/csilctl
```

## Cheat Sheet

> `csilctl` reads a `.csil` file. It lists the services and messages inside. It
> can also send a message to a host and show the response.

CSIL is the schema language from
[csilgen](https://github.com/catalystcommunity/csilgen). Point `csilctl` at a
`.csil` file with the global `--client` flag, before the subcommand.

### How to list all messages in a .csil file

Use `list` with no arguments. This prints the service and method names, and the
file's other types:

```sh
csilctl --client ./corndogs.csil list
```

### How to see the detail for one message or type

Name the method or type after `list`:

```sh
csilctl --client ./corndogs.csil list SubmitTask
csilctl --client ./corndogs.csil list Task
```

Add `--verbose` to print full request, response, and error field detail for
every message:

```sh
csilctl --client ./corndogs.csil list --verbose
```

### How to send a message

Name the message with `--message`. Give its payload as JSON with `--data`. Give
the destination with `--host` in `host:port` format:

```sh
csilctl --client ./corndogs.csil send \
  --message CreateWidget \
  --data '{"name": "widget-1", "count": 3}' \
  --host example.com:9000
```

If you leave a required field out of `--data`, `csilctl` prompts you for it.

### How to control colored output

`list` output is colored by default. Three controls set this, and they do not
all have the same priority:

```sh
csilctl --client ./corndogs.csil --disable-color list
NO_COLOR=1 csilctl --client ./corndogs.csil list
FORCE_COLOR=1 csilctl --client ./corndogs.csil list
```

`NO_COLOR` always wins. `FORCE_COLOR` wins over `--disable-color`, but not over
`NO_COLOR`. So this command still prints in color:

```sh
FORCE_COLOR=1 csilctl --client ./corndogs.csil --disable-color list
```

Set `NO_COLOR` in a CI environment, or in any script whose output you pipe to
another program, to keep control codes out of the stream.

### How to see all options

```sh
csilctl --help
csilctl list --help
csilctl send --help
```
