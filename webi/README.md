---
title: Webi
homepage: https://webinstall.dev
tagline: |
  Webi is how developers install their tools.
---

## Updating `webi`

```bash
webi webi
```

Since `webi` is just a small helper script, it's always update on each use.

## Cheat Sheet

> `webi` is what you would have created if you automated how you install your
> common tools yourself: Simple, direct downloads from official sources,
> unpacked into `~/.local`, added to `PATH`, symlinked for easy version
> switching, with minimal niceties like resuming downloads and 'stable' tags.

- Easy to remember.
- No magic, no nonesense, no bulk.
- What you would have done for yourself.

You can install _exactly_ what you need, from memory, via URL:

```bash
curl https://webinstall.dev/node@lts | bash
```

Or via `webi`, the tiny `curl | bash` shortcut command that comes with each
install:

```bash
webi node@lts golang@stable flutter@beta rustlang
```

### webi PATHs

You can see exactly what PATHs have been edited:

```bash
pathman list
```

And where:

```bash
cat ~/.config/envman/PATH.env
```

### Uninstall `webi`

`webi` uses standard paths and touches very little.

```bash
rm -rf ~/.local/opt ~/.local/bin
```

If you haven't used `pathman` for anything else, you can also remove its config:

```bash
rm -f ~/.config/envman/PATH.env
```
