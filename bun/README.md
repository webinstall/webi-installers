---
title: Bun
homepage: https://bun.sh
tagline: |
  Bun is a fast all-in-one JavaScript runtime
---

To update or switch versions, run `webi bun@<tag>`. \
(you can use `@beta` for pre-releases, or `@x.y.z` for a specific version)

### Files

These are the files / directories that are created and/or modified with this
install:

```text
~/.config/envman/PATH.env
~/.local/opt/bun/
~/.local/opt/bun-<VERSION>/
```

## Cheat Sheet

> Bun is a wicked-fast JavaScript runtime for developer tooling, API servers,
> and edge computing.
>
> It's built in Zig and provides a more curated, "batteries-included" approach
> to developing with JavaScript and JavaScript-ish languages - such as
> TypeScript, JSX, and TSX.

Run some <strong><em>x</em></strong>Script:

```sh
bun run ./hello.js
bun run ./hello.jsx
bun run ./hello.ts
bun run ./hello.tsx
```

Run a package from `npm`:

```sh
bun x jswt
```

More goodies:

```
bun help
```

(there's also a built-in **development server** and lots of stuff)

### bun<span>.</span>sh/install vs webi

Bun has an official installer:

```sh
export BUN_INSTALL="$HOME/.bun"
curl -fsSL https://bun.sh/install | bash
```

You might want to still use webi if you want to be able to switch between
versions.

### How to install command line completions

```sh
bun completions
```

### How to create a bun executable

1. Create your script
   ```sh
   vim ./hello
   ```
   ```js
   #!/usr/bin/env bun
   console.log('hello');
   ```
2. Make it executable
   ```sh
   chmod a+x ./hello
   ```
3. Run it
   ```sh
   ./hello
   ```

### How to publish bun packages

At the time of this writing (bun v0.5.1), you'll still need to publish with
`npm`.

`npm` is installed with [node](/node).

See
[Getting Started with NPM (as a developer)](https://gist.github.com/coolaj86/1318304).

### How to install bun packages

You can run it with `bun x`:

```sh
bun x <whatever>
```

Or you can put the `#!/usr/bin/env bun` shebang before publishing, and install
from npm:

```sh
bun install -g <whatever>
<whatever>
```

### How to run a Bun program as a service

As a system service on Linux:

(**note**: swap 'my-project' and './my-project' for the name of your project and
file)

1. Install serviceman (compatible with systemd)
   ```sh
   webi serviceman
   source ~/.config/envman/PATH.env
   ```
2. Go into your program's directory
   ```sh
   pushd ./my-project/
   ```
3. Add your project to the system launcher, running as the current user
   ```sh
   sudo env PATH="$PATH" \
       serviceman add --path="$PATH" --system \
           --username "$(whoami)" --name my-project -- \
       bun run ./my-project.js
   ```
4. Restart the logging service
   ```sh
   sudo systemctl restart systemd-journald
   ```

For **macOS**:

1. Install serviceman (compatible with `launchctl`)
   ```sh
   webi serviceman
   source ~/.config/envman/PATH.env
   ```
2. Go into your program's directory
   ```sh
   pushd ./my-project/
   ```
3. Add your project to the system launcher, running as the current user
   ```sh
   serviceman add --path="$PATH" --user --name my-project -- \
       bun run ./my-project.js
   ```
