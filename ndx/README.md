---
title: ndx
homepage: https://github.com/devlooped/ndx
tagline: |
  ndx: run NuGet-packaged native tools without a .NET SDK
---

To update or switch versions, run `webi ndx@stable` (or `@v1`, `@beta`, etc).

### Files

These are the files that are created and/or modified with this installer:

```text
~/.config/envman/PATH.env
~/.local/bin/ndx
~/.local/opt/ndx-VERSION/bin/ndx
```

## Cheat Sheet

> `ndx` is
> [`dnx`](https://learn.microsoft.com/dotnet/core/tools/dotnet-tool-exec) for
> native AOT tools on NuGet. Same `PACKAGE[@VERSION]` identity, same restore
> flags, same global packages folder — no SDK, no restore on a cached hit.

`--` separates ndx flags from the tool's arguments.

### How to run a NuGet tool

```sh
ndx stop -- --help
ndx dotnetsay@1.0.0 -- Hello
```

`stop` is a Native AOT RID tool. `dotnetsay` is a classic framework-dependent
tool. Both are just NuGet packages; ndx picks the host RID and starts
`Runner=executable` binaries directly, or `dotnet exec` for `Runner=dotnet`.

### How to pin an exact version

An exact pin is one-shot, like `dnx`: start that version and exit when the child
exits.

```sh
ndx stop@2.1.0 -- --help
```

### How to keep a long-running tool current

Unlike `dnx`, a bare package name is `@*` — not a one-shot latest. While the
child is still running, ndx watches the feed, downloads a newer matching
version, then sends SIGINT / Ctrl+C (and `WM_CLOSE` if the tool is a GUI) and
restarts.

```sh
ndx my-agent
ndx my-agent@*
ndx my-agent@*-*
ndx my-agent@1.*
ndx my-agent@[1.0,2.0)
```

`@*-*` includes prereleases. `@1.*` / `@1.1.*` float the rest the GitHub Actions
way. One-shot tools still exit as soon as the child exits; the watch loop only
continues while the child is alive.

### How to use a custom feed

```sh
ndx --source https://example.blob.core.windows.net/nuget/index.json \
    stop@2.1.0 -- --help
```

Shared flags match `dnx`: `--source`, `--add-source`, `--configfile`,
`--version`, `--prerelease`, `--yes`/`-y`, `--allow-roll-forward`,
`--verbosity`/`-v`, `--disable-parallel`, `--ignore-failed-sources`,
`--no-http-cache`, `--interactive`.

### How to change the evergreen poll interval

ndx walks from the working directory up, then `~/.netconfig`. Default is 5
seconds. `--verbosity quiet` hides the `Updating …` line.

```ini
[ndx]
    interval = 5
```
