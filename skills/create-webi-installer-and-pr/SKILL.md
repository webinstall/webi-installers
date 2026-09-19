---
name: create-webi-installer-and-pr
description: >
  Create or update a webi package installer and prepare its pull request.
  Use when adding a package, updating install.sh or install.ps1, or adapting
  an installer to a changed release asset or archive layout. Covers release
  asset inspection, POSIX shell and PowerShell installers, framework paths,
  archive extraction, and OS/architecture/variant checks. Release metadata in
  releases.conf is a separate concern.
compatibility: Requires git, curl, tar. GitHub API access needed for
  discovery phase.
---

# Webi Installer Skill

Write `install.sh` and `install.ps1` for a webi package. These scripts are
called by the webi framework after it has downloaded the selected package —
your job is to unpack or inflate it and place the files.

> **Scope:** This skill covers `install.sh` and `install.ps1` only. A
> separate `releases.conf` file is needed to tell webi where to fetch releases
> from. That config must already exist (or be written separately) before these
> install scripts are useful.

## Quick overview

1. [Discover the archive layout](#1-discover-the-archive-layout) — inspect
   GitHub releases with `curl` + `tar -t` to understand what's inside.
2. [Choose the install pattern](#2-choose-the-install-pattern) — ten
   named patterns cover almost every real-world case.
3. [Write `install.sh`](#3-write-installsh) — POSIX shell, ~20–40 lines.
4. [Write `install.ps1`](#4-write-installps1) — PowerShell, ~40–60 lines.
5. [Check for classification issues](#5-check-for-classification-issues) —
   look for variant assets, non-standard OS/arch naming, or installer .exe
   files that need special handling.

Full reference: [`references/PATTERNS.md`](references/PATTERNS.md)
Archive layout details: [`references/PATTERNS.md`](references/PATTERNS.md)
Classification guide: [`references/CLASSIFICATION.md`](references/CLASSIFICATION.md)

## README purpose and Files section

The Webi README is a daily-driver guide, not a copy of the project's README.
Highlight:

- options an average user would want or expect as defaults;
- footguns and nuances that matter in the common use case;
- practical usage details that help an AI use the tool correctly without
  obvious reminders such as `--version` or `--help`.

Do not cover esoteric options, write a complete reference, or duplicate the
upstream README. Keep the cheat sheet short and practical.

Use progressive disclosure for the README flow:

1. Orient the reader with the tagline and a one-line purpose.
2. Show `### Files` and the paths users need to know.
3. Give one happy-path example that can be copied and run.
4. Add a ToC before the longer task recipes when there are several sections.
5. Organize recipes by user task, from common setup to advanced integration.
6. Put footguns beside the task they affect; link to upstream reference docs for
   exhaustive details.

Do not repeat the Files list in the ToC or prose. Do not add a ToC just to list
flags. The README should get a user from "what is this?" to a useful daily
driver setup with as little rediscovery as possible.

Use these complex README examples as models:

| README | Good model for |
| --- | --- |
| `serviceman/README.md` | Cross-platform services, platform nuances, and unit examples. |
| `postgres/README.md` | Server setup, service registration, config, and secure remote access. |
| `mariadb/README.md` | Service setup, config, auth, remote access, and backups. |
| `psql/README.md` | Client config, authentication, TLS, and common workflows. |
| `goreleaser/README.md` | Practical build and release workflows with config examples. |

When the package README has a `### Files` section, enumerate the files and
paths the installer creates or uses. Include at least the default directories
where the tool stores configuration or data, even if the installer does not
create them immediately. Also list the installed binary, versioned install
path, PATH configuration, and any other default runtime paths when known.

Example:

```text
~/.config/envman/PATH.env
~/.config/tool/config.toml
~/.local/share/tool/
~/.cache/tool/
~/.local/bin/tool
```

## 1. Discover the archive layout

### Use the webi releases API (fastest, if the package already exists)

```sh
# JSON with all releases for a package
curl -s https://webinstall.dev/api/releases/bat.json | jq '.releases[:3]'
```

Each entry has `name` (filename), `version`, `os`, `arch`, `ext`, `download`.

### Or inspect GitHub releases directly

```sh
# List asset filenames for the latest release
curl -s "https://api.github.com/repos/sharkdp/bat/releases?per_page=3" \
  | jq '.[0].assets[] | .name'
```

### Inspect what's inside an archive

Download one representative asset and list its contents **without extracting**:

```sh
# tar.gz / tar.xz
curl -fsSL "$DOWNLOAD_URL" | tar -tz

# tar.zst (modern systems — GNU tar / bsdtar both support this)
curl -fsSL "$DOWNLOAD_URL" | tar --zstd -tz

# zip
curl -fsSL "$DOWNLOAD_URL" -o /tmp/pkg.zip && unzip -l /tmp/pkg.zip

# bare binary, optionally compressed (e.g. jq-linux-amd64 or tool.xz)
# The download contains one binary, not an archive of files. This is the
# waif pattern: set WEBI_SINGLE=true and rely on framework defaults.
```

Look for:
- Is the binary at the top level or inside a subdirectory?
- Does the subdirectory name include the version and/or triplet?
- Are there completions (`completions/`, `autocomplete/`, `complete/`)?
- Are there man pages (`*.1`, `doc/*.1`, `man/man1/`)?
- Are there shared libraries (`.so`, `.dylib`, `.dll`) alongside the binary?
- Is the binary name different from the package command name?

See [`references/PATTERNS.md`](references/PATTERNS.md) for
what each pattern looks like, with real examples. Waif downloads contain
one binary, so there may be no archive listing to inspect.


## 2. Choose the install pattern

| Pattern | Description | Examples |
|---------|-------------|----------|
| **waif** | Single bare or compressed binary — no archive of files | jq, shfmt |
| **idealist** | Single binary (or binary+docs) at archive root | caddy, fzf, k9s, terraform |
| **prestige** | Binary inside a version/triplet-named subdirectory | bun, delta, shellcheck, trip, xsv |
| **heretic** | Gang's all there, but in a bespoke, convention-defying layout | bat, fd, rg, sd, watchexec, zoxide |
| **caravan** | Binary + shared libraries (bundled) | ollama (Linux), psql, sass, syncthing |
| **completionist** | FHS-like layout (`bin/`, `share/man/`) | gh, pandoc |
| **pseudos** | Renamed binary needing install-time rename | pathman, yq |
| **legion** | Full SDK/toolchain (many files) | go, node, zig, flutter, julia |
| **el mono** | .NET runtime bundle | pwsh |
| **pantheon** | Multi-binary distribution | dashcore, mutagen |

### Classification quick reference

| Field | Common filename forms | Legacy output / action |
|---|---|---|
| OS | `linux`, `darwin`, `windows`, BSDs | `darwin` usually exports as `macos` |
| Arch | `x86_64`/`amd64`, `aarch64`/`arm64`, `armv7` | Usually exports as `amd64`, `arm64`, `armv7l` |
| Libc | `gnu`/`glibc`, `musl`, `msvc`, `static` | Keep `gnu`, `musl`, `msvc`, or `none` |
| Format | `tar.gz`, `tar.xz`, `tar.zst`, `zip`, bare file | Use the framework's matching extractor |
| Variants | `cuda`, `rocm`, `baseline`, `profile`, `Setup.exe` | Tag or exclude competing builds |

The Go classifier's native values and the legacy cache's values differ. See
[`references/CLASSIFICATION.md`](references/CLASSIFICATION.md) for the full
mapping and target-name rules.

**idealist** is by far the most common (~28 packages). When in doubt,
download the archive and `tar -tz` it before writing a single line of code.


## 3. Write `install.sh`

The framework (`_webi/package-install.tpl.sh`) handles: user-agent detection,
version resolution, download, extraction, and PATH management. It does not
verify checksums for downloaded package archives.
Your script is **injected into** the framework and provides the
package-specific part: where to find the binary and how to move it.

### Script structure

Many newer `install.sh` files wrap their definitions in an
`__init_pkgname()` function and immediately call it. This is a useful pattern,
but not required: the framework already injects the script inside
`__init_installer()`. Existing packages use both styles:

```sh
#!/bin/sh

__init_toolname() {
    set -e
    set -u

    ####################
    # Install toolname #
    ####################

    pkg_cmd_name="toolname"
    WEBI_SINGLE=true   # if applicable — see below

    pkg_dst_cmd="$HOME/.local/bin/toolname"
    pkg_dst="$pkg_dst_cmd"

    pkg_src_cmd="$HOME/.local/opt/toolname-v$WEBI_VERSION/bin/toolname"
    pkg_src_dir="$HOME/.local/opt/toolname-v$WEBI_VERSION"
    pkg_src="$pkg_src_cmd"

    pkg_install() {
        # ...
    }

    pkg_get_current_version() {
        # ...
    }

}

__init_toolname
```

### Variables

| Variable | Description |
|----------|-------------|
| `pkg_cmd_name` | The command name that ends up on `$PATH` |
| `pkg_dst_cmd` | Final destination: `~/.local/bin/<cmd>` (the symlink) |
| `pkg_dst` | Same as `pkg_dst_cmd` for single-binary packages; `~/.local/opt/<cmd>` for SDKs |
| `pkg_src_cmd` | Versioned binary: `~/.local/opt/<pkg>-v<ver>/bin/<cmd>` |
| `pkg_src_dir` | Versioned install dir: `~/.local/opt/<pkg>-v<ver>` |
| `pkg_src` | Same as `pkg_src_cmd` for single-binary packages; same as `pkg_src_dir` for SDKs |

**Framework-derived (set by the framework before calling `pkg_install` — do not set manually):**
- `pkg_src_bin` — `$(dirname "$pkg_src_cmd")` — the versioned `bin/` dir
- `pkg_dst_bin` — `$(dirname "$pkg_dst_cmd")` — `~/.local/bin`

### `WEBI_SINGLE`

`WEBI_SINGLE=true` affects the default values the framework uses for
`pkg_src` and `pkg_dst`, and how `webi_link()` creates the symlink:

- **With `WEBI_SINGLE=true`**: links the binary file directly:
  `~/.local/bin/cmd → ~/.local/opt/cmd-vX.Y.Z/bin/cmd`
- **Without it (default)**: links the directory:
  `~/.local/opt/cmd → ~/.local/opt/cmd-vX.Y.Z`

Set `WEBI_SINGLE=true` when using the conventional **idealist** skeleton
(where `pkg_src` and `pkg_dst` are not set to custom values). When you
explicitly assign all six variables yourself (as in **prestige** through **pseudos**),
`WEBI_SINGLE` is not strictly required but can still be set for clarity.

**legion** (SDKs) and **el mono** (.NET bundles) do NOT use `WEBI_SINGLE` —
they define `pkg_link()` manually because the whole directory tree must
be linked, not just a single binary.

### Required function: `pkg_install`

Moves files from the extracted archive into the versioned opt directory.
The framework has already extracted the archive into a temp directory and
`cd`'d into it before calling `pkg_install`.

```sh
pkg_install() {
    mkdir -p "$pkg_src_bin"
    mv ./tool-*/tool "$pkg_src_cmd"
    chmod a+x "$pkg_src_cmd"
}
```

### Recommended function: `pkg_get_current_version`

Used to detect whether the package is already installed at the right version:

```sh
pkg_get_current_version() {
    # 'tool --version' output: "tool 1.2.3 (rev abc)"
    # trim to just the version number
    tool --version 2>/dev/null | head -n 1 | cut -d' ' -f2
}
```

### Skeletons by pattern

**waif** — single bare binary, optionally compressed (`WEBI_SINGLE=true`):
The download contains one binary, not an archive of files. For an uncompressed
binary, the framework detects `WEBI_EXT=exe` and moves it into the temp dir.
For a supported single-file compression format, it inflates the file first.
The default `webi_install()` moves it into place and `chmod a+x` is applied
automatically. No `pkg_install` function is needed — just set
`WEBI_SINGLE=true`:
```sh
WEBI_SINGLE=true

pkg_get_current_version() {
    jq --version 2>/dev/null | head -n 1 | sed 's:^jq-::'
}
```

**idealist** — binary at archive root (`WEBI_SINGLE=true`):
```sh
WEBI_SINGLE=true
pkg_install() {
    mkdir -p "$pkg_src_bin"
    mv ./"$pkg_cmd_name"* "$pkg_src_cmd"
    chmod a+x "$pkg_src_cmd"
}
```
Use `$pkg_cmd_name*` as the glob — it matches the binary and avoids
accidentally moving LICENSE or README into the binary path.

**prestige** — binary inside a `tool-{ver}-{triplet}/` subdirectory:
```sh
# WEBI_SINGLE not required when all 6 variables are set explicitly
pkg_install() {
    mkdir -p "$pkg_src_bin"
    mv ./tool-*/tool "$pkg_src_cmd"
    chmod a+x "$pkg_src_cmd"
}
```

**heretic** — gang's all there, but in a bespoke, convention-defying layout.
The completion directory and filename vary per package — always check
`tar -tz` output first. Common variants: `completions/`, `autocomplete/`,
`complete/`. See [`references/PATTERNS.md`](references/PATTERNS.md) for
a full example with guards:
```sh
WEBI_SINGLE=true
pkg_install() {
    mkdir -p "$pkg_src_bin"
    mv ./tool-*/tool "$pkg_src_cmd"
    chmod a+x "$pkg_src_cmd"

    # bash completion (directory name varies — check tar -tz)
    if test -e ./tool-*/completions/tool.bash; then
        mkdir -p "$pkg_src_dir/share/bash-completion/completions"
        mv ./tool-*/completions/tool.bash \
            "$pkg_src_dir/share/bash-completion/completions/tool"
    fi
    if test -e ./tool-*/completions/tool.fish; then
        mkdir -p "$pkg_src_dir/share/fish/vendor_completions.d"
        mv ./tool-*/completions/tool.fish \
            "$pkg_src_dir/share/fish/vendor_completions.d/tool.fish"
    fi
    if test -e ./tool-*/completions/_tool; then
        mkdir -p "$pkg_src_dir/share/zsh/site-functions"
        mv ./tool-*/completions/_tool \
            "$pkg_src_dir/share/zsh/site-functions/_tool"
    fi
    if test -e ./tool-*/tool.1; then
        mkdir -p "$pkg_src_dir/share/man/man1"
        mv ./tool-*/tool.1 "$pkg_src_dir/share/man/man1/tool.1"
    fi
}
```

**caravan** — binary + shared libraries. The entire directory structure
must be preserved. See [`references/PATTERNS.md`](references/PATTERNS.md)
for the ollama and psql examples.

**completionist** — FHS layout (archive already has `bin/` and `share/`):
```sh
WEBI_SINGLE=true
pkg_install() {
    mkdir -p "$(dirname "$pkg_src_dir")"
    mv ./tool-*/ "$pkg_src_dir"
}
```

**pseudos** — binary needs rename (archive name ≠ command name).
Use when the binary in the archive cannot be matched by `$pkg_cmd_name*`
— e.g., `yq_linux_amd64` for a command named `yq`:
```sh
WEBI_SINGLE=true
pkg_install() {
    mkdir -p "$pkg_src_bin"
    mv ./yq_* "$pkg_src_cmd"
    chmod a+x "$pkg_src_cmd"
}
```

**legion** — full SDK (do NOT set `WEBI_SINGLE`):
```sh
# pkg_src = directory, not a binary
pkg_src="$pkg_src_dir"
pkg_dst="$HOME/.local/opt/tool"

pkg_install() {
    mkdir -p "$(dirname "$pkg_src_dir")"
    mv ./tool-*/ "$pkg_src_dir"
}

pkg_link() {
    rm -f "$pkg_dst"
    ln -s "$pkg_src" "$pkg_dst"
}
```


## 4. Write `install.ps1`

A PowerShell framework template exists (`_webi/package-install.tpl.ps1`)
and injects the `install.ps1` script at the `# {{ installer }}` placeholder.
The template provides: error handling, directory setup, `Invoke-DownloadUrl`
helper, and PATH management via `webi_path_add`. However, unlike the shell
side, the PS1 framework does **not** download or extract the archive — the
package script must handle that itself. The same path conventions apply
(opt/bin layout), but Windows uses `Copy-Item` instead of symlinks for
the final `bin/` step.

### Variable block (always at top)

```powershell
$pkg_cmd_name = "tool"

$pkg_dst_cmd = "$Env:USERPROFILE\.local\bin\tool.exe"
$pkg_dst_bin = "$Env:USERPROFILE\.local\bin"
$pkg_dst = "$pkg_dst_cmd"

$pkg_src_cmd = "$Env:USERPROFILE\.local\opt\tool-v$Env:WEBI_VERSION\bin\tool.exe"
$pkg_src_bin = "$Env:USERPROFILE\.local\opt\tool-v$Env:WEBI_VERSION\bin"
$pkg_src_dir = "$Env:USERPROFILE\.local\opt\tool-v$Env:WEBI_VERSION"
$pkg_src = "$pkg_src_cmd"
```

### Standard body

```powershell
New-Item "$Env:USERPROFILE\Downloads\webi" -ItemType Directory -Force | Out-Null
$pkg_download = "$Env:USERPROFILE\Downloads\webi\$Env:WEBI_PKG_FILE"

# Fetch archive
if (!(Test-Path -Path "$pkg_download")) {
    Write-Output "Downloading tool from $Env:WEBI_PKG_URL to $pkg_download"
    & curl.exe -A "$Env:WEBI_UA" -fsSL "$Env:WEBI_PKG_URL" -o "$pkg_download.part"
    & Move-Item "$pkg_download.part" "$pkg_download"
}

if (!(Test-Path -Path "$pkg_src_cmd")) {
    Write-Output "Installing tool"

    Push-Location .local\tmp
        Remove-Item -Path ".\tool-v*" -Recurse -ErrorAction Ignore

        # Unpack — Windows BSD-tar handles zip too
        Write-Output "Unpacking $pkg_download"
        & tar xf "$pkg_download"

        # Move binary into place — adjust glob for your archive structure
        Write-Output "Install Location: $pkg_src_cmd"
        New-Item "$pkg_src_bin" -ItemType Directory -Force | Out-Null
        Move-Item -Path ".\tool-*\tool.exe" -Destination "$pkg_src_bin"
    Pop-Location
}

# Windows has no symlinks in the webi sense — copy to bin/
Write-Output "Copying into '$pkg_dst_cmd' from '$pkg_src_cmd'"
Remove-Item -Path "$pkg_dst_cmd" -Recurse -ErrorAction Ignore | Out-Null
New-Item "$pkg_dst_bin" -ItemType Directory -Force | Out-Null
Copy-Item -Path "$pkg_src" -Destination "$pkg_dst" -Recurse
```

For **idealist** (binary at archive root), change the `Move-Item` line to:
```powershell
Move-Item -Path ".\tool.exe" -Destination "$pkg_src_bin"
```


## 5. Check for classification issues

Before writing any scripts, scan the asset list for red flags:

### Non-standard OS/arch names in filenames

The webi classifier recognises most patterns automatically. Watch for:
- `darwin` vs `macos` — both recognised; legacy output is usually `macos`
- `x86_64` vs `amd64` — both recognised; legacy output is `amd64`
- `aarch64` vs `arm64` — both recognised; legacy output is `arm64`
- `armv7` / `armv7l` — recognised; legacy output is usually `armv7l`

The Go classifier uses its own native values (`darwin`, `x86_64`, `aarch64`,
`armv7`). Legacy export translates these for the Node.js-compatible cache.
Only flag them if the asset list contains something genuinely unusual that the
classifier would not recognise.

### Variant assets needing tags

Flag if you see multiple assets for the same OS/arch that serve different
hardware or runtime requirements:
- **GPU variants**: `*-rocm*`, `*-cuda*`, `*-vulkan*` alongside a baseline build
- **Windows installer**: `*Setup.exe` or `*Install.exe` alongside a bare `*.exe`
- **Framework-dependent .NET**: `*-fxdependent*` vs self-contained
- **AppImage**: `*.AppImage` — not supported by the webi installer
- **Electron/GUI app**: `*.dmg` or `*.AppImage` that is a full GUI app, not a CLI

If you find variants, see [`references/CLASSIFICATION.md`](references/CLASSIFICATION.md)
for how to write a variant tagger.

### Formats to drop

Use `exclude` only for extensions or filename patterns that are likely to be
misclassified or are not relevant to an installer. Do not use it just to remove
supported duplicate archive formats or CPU variants; the legacy cacher handles
those cases and can choose the right asset as its compatibility logic improves.

Common non-installer assets filtered automatically from the legacy export:
- `.deb`, `.rpm`, `.snap`, `.AppImage`
- Checksums (`*.sha256`, `*.sha512`, `*.asc`, `*.sig`)
- Source archives (`*-src.tar.gz`, `*.tar.gz` with no OS in name)


## Reference files

- [`references/PATTERNS.md`](references/PATTERNS.md) — detailed pattern
  descriptions with real package examples and complete install script snippets
- [`references/PATTERNS.md`](references/PATTERNS.md) — actual
  `tar -t` output for representative packages in each pattern
- [`references/CLASSIFICATION.md`](references/CLASSIFICATION.md) — when and
  how to write variant taggers; non-standard filename conventions
