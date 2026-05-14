# Webi Installers — Agent Guide

Webi installs dev tools to `~/.local/` without sudo. Each installer is a small
package of 3-4 files. This guide tells you how to create and modify them.

## Why Webi Exists

Webi makes tool installation trivially repeatable for people who aren't
sysadmins — freelance clients, junior devs, anyone who shouldn't have to care
about PATH, permissions, or platform differences. Three things matter:

1. **Install without friction.** No sudo, no manual PATH edits, no "necessary
   but unimportant" steps leaking into the experience.
2. **Know where things are.** The Files section tells you exactly what got
   created or modified. Nothing should be mysterious.
3. **Copy-paste recipes.** The cheat sheet is what you'd send someone less
   experienced than yourself instead of a project's full README — scannable,
   concrete, easy to reference by name.

## Quick Start: Adding a New Installer

1. Identify the **package type** (see [Categories](#categories) below)
2. Find an existing installer of the same type to use as a template
3. Create `<name>/releases.js`, `install.sh`, `install.ps1`, `README.md`
4. Test with the command in [Testing releases.js](#testing-releasesjs)
5. Run formatters before committing (see [Code Style](#code-style))

## Directory Layout

```
<package-name>/
  README.md          # YAML frontmatter + docs
  releases.js        # Fetches release metadata (Node.js)
  install.sh         # POSIX shell installer (macOS/Linux)
  install.ps1        # PowerShell installer (Windows) — optional
```

Key infrastructure directories (do not modify without good reason):

- `_webi/` — bootstrap templates, `normalize.js` (auto-detects OS/arch/ext from
  filenames)
- `_common/` — shared JS: `github.js`, `githubish.js`, `gitea.js`, `fetcher.js`
- `_example/` — canonical template for new packages
- `_examples/` — specialized templates (goreleaser, xz-compressed)

## Categories

Ref: <https://github.com/webinstall/webi-installers/issues/412>

| Type  | Description                            | Template to copy |
| ----- | -------------------------------------- | ---------------- |
| `bin` | Single binary in tar/zip               | `koji`, `delta`  |
| `bin` | Single bare binary (no archive)        | `arc`, `shfmt`   |
| `bin` | Goreleaser-style archives              | `keypairs`       |
| 📦    | Self-contained package (bin/man/share) | `node`, `go`     |
| 📂    | Multiple binaries/scripts              | `pg`             |
| 🔗    | Alias/redirect to another package      | `ripgrep` → `rg` |
| 📝    | Bespoke / custom install               | `rustlang`       |

## releases.js

Fetches release metadata and returns a normalized object. Most packages use
GitHub releases:

```js
'use strict';

var github = require('../_common/github.js');
var owner = 'OWNER';
var repo = 'REPO';

let Releases = module.exports;

Releases.latest = async function () {
  let all = await github(null, owner, repo);
  return all;
};

Releases.sample = async function () {
  let normalize = require('../_webi/normalize.js');
  let all = await Releases.latest();
  all = normalize(all);
  all.releases = all.releases.slice(0, 5);
  return all;
};

if (module === require.main) {
  (async function () {
    let samples = await Releases.sample();
    console.info(JSON.stringify(samples, null, 2));
  })();
}
```

### Common release transformations

**Strip version prefix** (monorepo or tool-prefixed tags):

```js
// e.g. "tools/monorel/v0.6.5" → "v0.6.5"
rel.version = rel.version.replace(/^tools\/monorel\//, '');

// e.g. "cli-v1.2.3" → "v1.2.3"
rel.version = rel.version.replace(/^cli-/, '');
```

**Filter releases** (monorepo with multiple tools, or unwanted assets):

```js
all.releases = all.releases.filter(function (rel) {
  // Keep only releases for this tool
  return rel.version.startsWith('tools/monorel/');
});
```

Apply transformations inside `Releases.latest`, before returning `all`.

**Available sources** beyond `github.js`:

- `_common/gitea.js` — Gitea servers
- `_common/git-tag.js` — Git tag listing
- Custom fetch from any JSON API (see `go/releases.js`, `terraform/releases.js`)

### Testing releases.js

```sh
node -e "
  let Releases = require('./<name>/releases.js');
  Releases.sample().then(function (all) {
    console.log(JSON.stringify(all, null, 2));
  });
"
```

Verify: versions are clean semver (`0.6.5` not `tools/monorel/v0.6.5`), OS/arch
detected correctly, download URLs resolve.

## install.sh

POSIX shell (`sh`, not bash). Always wrapped in a function:

```sh
#!/bin/sh
# shellcheck disable=SC2034

set -e
set -u

__init_pkgname() {
    # These 6 variables are required
    pkg_cmd_name="cmd"

    pkg_dst_cmd="$HOME/.local/bin/cmd"
    pkg_dst="$pkg_dst_cmd"

    pkg_src_cmd="$HOME/.local/opt/cmd-v$WEBI_VERSION/bin/cmd"
    pkg_src_dir="$HOME/.local/opt/cmd-v$WEBI_VERSION"
    pkg_src="$pkg_src_cmd"

    pkg_install() {
        mkdir -p "$(dirname "$pkg_src_cmd")"
        mv ./cmd "$pkg_src_cmd"
    }

    pkg_get_current_version() {
        cmd --version 2> /dev/null | head -n 1 | cut -d' ' -f2
    }
}

__init_pkgname
```

### Framework variables available in install.sh

Set by the webi bootstrap (`_webi/package-install.tpl.sh`):

| Variable        | Example             | Description           |
| --------------- | ------------------- | --------------------- |
| `WEBI_VERSION`  | `1.2.3`             | Selected version      |
| `WEBI_PKG_URL`  | `https://...`       | Download URL          |
| `WEBI_PKG_FILE` | `foo-v1.2.3.tar.gz` | Download filename     |
| `WEBI_OS`       | `linux`             | Detected OS           |
| `WEBI_ARCH`     | `amd64`             | Detected architecture |
| `WEBI_EXT`      | `tar.gz`            | Archive extension     |
| `WEBI_CHANNEL`  | `stable`            | Release channel       |
| `PKG_NAME`      | `foo`               | Package name          |

### Override functions

| Function                    | Purpose                                       |
| --------------------------- | --------------------------------------------- |
| `pkg_install()`             | **Required.** Move files to `$pkg_src`        |
| `pkg_get_current_version()` | Parse installed version from command output   |
| `pkg_post_install()`        | Post-install setup (git config, shell config) |
| `pkg_done_message()`        | Custom completion message                     |
| `pkg_link()`                | Override default symlink behavior             |
| `pkg_pre_install()`         | Custom pre-install logic                      |

### Framework helper functions

| Function                 | Purpose                            |
| ------------------------ | ---------------------------------- |
| `webi_download()`        | Download package if not cached     |
| `webi_extract()`         | Extract archive by extension       |
| `webi_path_add <dir>`    | Add to PATH via envman             |
| `webi_link()`            | Create versioned symlinks          |
| `webi_check_installed()` | Check if version already installed |

### pkg_install patterns

**Bare binary in archive root:**

```sh
mv ./cmd "$pkg_src_cmd"
```

**Binary in a subdirectory (goreleaser-style `cmd-OS-arch/cmd`):**

```sh
mv ./cmd-*/cmd "$pkg_src_cmd"
```

**Flexible detection (handles multiple archive layouts):**

```sh
if test -f ./cmd; then
    mv ./cmd "$pkg_src_cmd"
elif test -e ./cmd-*/cmd; then
    mv ./cmd-*/cmd "$pkg_src_cmd"
elif test -e ./cmd-*; then
    mv ./cmd-* "$pkg_src_cmd"
fi
```

## install.ps1

PowerShell for Windows. Uses `$Env:` variables. See `_example/install.ps1` for
the full template. Key differences from install.sh:

- Paths use backslashes, commands end in `.exe`
- `$Env:USERPROFILE` instead of `$HOME`
- `Test-Path`, `Move-Item`, `Copy-Item` instead of shell equivalents
- Downloads go to `$Env:USERPROFILE\Downloads\webi\`
- Temp work in `.local\tmp`, use `Push-Location`/`Pop-Location`
- Symlinks done via `Copy-Item` (not actual symlinks)

## README.md

````markdown
---
title: toolname
homepage: https://github.com/owner/repo
tagline: |
  toolname: A short one-line description.
---

To update or switch versions, run `webi toolname@stable` (or `@v2`, `@beta`,
etc).

### Files

These are the files that are created and/or modified with this installer:

```text
~/.config/envman/PATH.env
~/.local/bin/toolname
~/.local/opt/toolname-VERSION/bin/toolname
```

## Cheat Sheet

> `toolname` does X. Brief description.

### How to use toolname

```sh
toolname --example
```
````

Note: **Files goes above Cheat Sheet**, not inside it.

### Cheat Sheet tone and style

Webi cheat sheets are **opinionated quick-reference guides**, not comprehensive
documentation. Think "colleague's sticky note" — not the project's official
README.

The tool is the topic, but **the problem is the reason**. Cheat sheets are
organized around tasks the reader already wants to do — the tool is how they get
there. Headings reference the tool (the reader came to this page on purpose),
but the content solves the underlying problem completely:

- "How to reverse proxy to Node" (caddy knowledge, not just node)
- "How to run a Node app as a System Service" (serviceman knowledge)
- "How to Enable Secure Remote Postgres Access" (openssl, pg_hba.conf, systemd)
- "How to manually configure git to use delta" (gitconfig, not delta flags)
- "How to make fish the default shell in iTerm2" (iTerm2 knowledge, not fish)

The reader's question is "how do I do X?" and the cheat sheet answers it
completely — including configs, adjacent tools, and platform-specific
variations. A goreleaser cheat sheet teaches you goreleaser YAML. A postgres
cheat sheet teaches you pg_hba.conf, openssl certs, and systemd units.

Cheat sheets cross tool boundaries freely. Node's references caddy, serviceman,
setcap-netbind, GitHub Actions. Postgres references serviceman, openrc, launchd.
They link to each other's webi pages. The scope is "everything you need to
accomplish this task," not "everything this one binary does."

They show the actual files and configs that matter — not documentation _about_
configs, but the configs themselves, copy-pasteable, with inline comments
explaining the non-obvious parts.

**Guidelines:**

- **Show the 3-5 things someone will actually do**, with copy-pasteable
  commands. Skip exhaustive flag lists and API docs.
- **Lead with practical integration.** Show the exact `git config` lines, the
  exact hook script, the exact shell alias — don't just explain the feature and
  leave wiring up to the reader.
- **Skip what they already know.** No need to re-explain what the tool is at
  length — the tagline and one-liner blockquote handle that. Get to the
  commands.
- **Prefer concrete over abstract.** Instead of "you can configure X via a
  config file", show the config file contents.

## Shell Naming Conventions

**Variables:**

- `ALL_CAPS` — environment variables only (`PATH`, `HOME`, `WEBI_VERSION`)
- `b_varname` — block-scoped (inside a function, loop, or conditional)
- `g_varname` — global to the script (and sourced scripts)
- `a_varname` — function arguments

**Functions and commands:**

- `fn_name` — helper functions (anything other than the script's main/entry
  function)
- `cmd_name` — command aliases, e.g. `cmd_curl='curl --fail-with-body -sSL'`

## Code Style

Requires `node`, `shfmt`, `pwsh`, and `pwsh-essentials` (install all via webi).
Run before committing:

```sh
npm run fmt         # prettier (JS/MD) + shfmt (sh) + pwsh-fmt (ps1)
npm run lint        # jshint + shellcheck + pwsh-lint
```

Commit messages: `feat(<pkg>): add installer`, `fix(<pkg>): update install.sh`,
`docs(<pkg>): add cheat sheet`.

## Naming Conventions

- The canonical package name is the **command name** you type: `go`, `node`,
  `rg`
- The alternate/alias name is the project name: `golang`, `nodejs`, `ripgrep`
- Package directories are lowercase with hyphens

## Common Pitfalls

- **Monorepo releases**: The GitHub API returns ALL releases for the repo. You
  must filter in `releases.js` and strip the tag prefix from the version.
- **No `--version` flag**: Some tools lack version introspection. Comment out
  `pkg_get_current_version` — webi still works, it just can't skip reinstalls.
- **normalize.js auto-detection**: OS/arch/ext are guessed from download
  filenames. If the tool uses non-standard naming, you may need to set `os`,
  `arch`, or `ext` explicitly in `releases.js`.
- **Goreleaser archives**: Typically contain a bare binary at the archive root
  (not nested in a directory). Use `mv ./cmd "$pkg_src_cmd"`.
