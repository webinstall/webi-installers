---
title: bunpm
homepage: https://github.com/yv3000/bunpm
tagline: |
  bunpm: Zero-runtime-dependency CLI that transparently routes npm, yarn, and pnpm through Bun for 20x faster package installs.
---

To update or switch versions, run `webi bunpm@stable` (or `@v2.3.9`, `@beta`, etc).

### Files

These are the files / directories that are created and/or modified with this install:

```text
~/.config/envman/PATH.env
~/.local/bin/bunpm
~/.local/bin/npm
~/.local/bin/npx
~/.local/bin/yarn
~/.local/bin/pnpm
~/.local/opt/bunpm/
```

## Cheat Sheet

> `bunpm` transparently routes your package manager commands through Bun at lightning speed, while falling back safely to native npm/yarn/pnpm if a command or flag cannot be safely mapped.

### Verify Installation:

```sh
bunpm doctor
```

### Transparent Usage:

Just use your regular package manager commands as you normally would:

```sh
npm install express
npx prettier --check .
yarn add react
pnpm add lodash
```

### Fail-Closed Fallback Guarantee:

Commands that cannot be translated safely (e.g. `npm audit`, `npm publish`, `npm login`, or Yarn PnP workspaces) automatically hand execution directly back to the original manager without broken builds.

### Prerequisites:

`bunpm` requires both [Node.js](https://webinstall.dev/node) (>=16.9.0) and [Bun](https://webinstall.dev/bun) to be installed.
