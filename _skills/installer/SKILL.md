---
name: installer
description: >
  Create or update install.sh and install.ps1 scripts for a webi package.
  Use when adding a new package to webi-installers, or when an existing
  install script needs to be updated to match a changed archive structure.
  Covers discovering archive layout from GitHub releases, identifying the
  right install pattern (A–I), and writing both the POSIX shell and
  PowerShell scripts that the webi framework calls.
  Note: this skill covers install scripts only — writing releases.js /
  releases.conf (the release-fetcher config) is a separate concern.
license: MIT
compatibility: Requires git, curl, tar. GitHub API access needed for
  discovery phase. Designed for Claude Code in the webi-installers repo.
metadata:
  author: AJ ONeal
  version: "1.1"
---

# Webi Installer Skill

Write `install.sh` and `install.ps1` for a webi package. These scripts are
called by the webi framework **after** it has already downloaded and verified
the archive — your job is only to unpack and place the files.

> **Scope:** This skill covers `install.sh` and `install.ps1` only. A
> separate `releases.js` / `releases.conf` file is needed to tell webi where
> to fetch releases from. That config must already exist (or be written
> separately) before these install scripts are useful.

## Quick overview

1. [Discover the archive layout](#1-discover-the-archive-layout) — inspect
   GitHub releases with `curl` + `tar -t` to understand what's inside.
2. [Choose the install pattern](#2-choose-the-install-pattern) — nine
   patterns (A–I) cover almost every real-world case.
3. [Write `install.sh`](#3-write-installsh) — POSIX shell, ~20–40 lines.
4. [Write `install.ps1`](#4-write-installps1) — PowerShell, ~40–60 lines.
5. [Check for classification issues](#5-check-for-classification-issues) —
   look for variant assets, non-standard OS/arch naming, or installer .exe
   files that need special handling.

Full reference: [`references/PATTERNS.md`](references/PATTERNS.md)
Archive layout details: [`references/ARCHIVE-LAYOUTS.md`](references/ARCHIVE-LAYOUTS.md)
Classification guide: [`references/CLASSIFICATION.md`](references/CLASSIFICATION.md)

---

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

# bare binary (no archive extension, e.g. jq-linux-amd64)
# The file IS the binary — no unpacking needed. Set WEBI_SINGLE=true.
```

Look for:
- Is the binary at the top level or inside a subdirectory?
- Does the subdirectory name include the version and/or triplet?
- Are there completions (`completions/`, `autocomplete/`, `complete/`)?
- Are there man pages (`*.1`, `doc/*.1`, `man/man1/`)?
- Are there shared libraries (`.so`, `.dylib`, `.dll`) alongside the binary?
- Is the binary name different from the package command name?

See [`references/ARCHIVE-LAYOUTS.md`](references/ARCHIVE-LAYOUTS.md) for
what each pattern looks like, with real examples.

---

## 2. Choose the install pattern

| Pattern | Description | Examples |
|---------|-------------|---------|
| **A** | Bare binary (or binary+docs) at archive root | caddy, fzf, k9s, terraform |
| **B** | Binary inside a version/triplet-named subdirectory | delta, shellcheck, trip, xsv |
| **C** | Like B, plus shell completions and/or man pages | bat, fd, rg, sd, watchexec, zoxide |
| **D** | Binary + shared libraries (bundled) | ollama (Linux), psql, sass, syncthing |
| **E** | FHS-like layout (`bin/`, `share/man/`) | gh, pandoc |
| **F** | Renamed binary needing install-time rename | pathman, yq |
| **G** | Full SDK/toolchain (many files) | go, node, zig, flutter, julia |
| **H** | .NET runtime bundle | pwsh |
| **I** | Multi-binary distribution | dashcore, mutagen |

**Pattern A** is by far the most common (~28 packages). When in doubt,
download the archive and `tar -tz` it before writing a single line of code.

---

## 3. Write `install.sh`

The framework (`_webi/package-install.tpl.sh`) handles: user-agent detection,
version resolution, download, checksum verification, and PATH management.
Your script is **injected into** the framework and provides the
package-specific part: where to find the binary and how to move it.

### Script structure

Every `install.sh` wraps its definitions in an `__init_pkgname()` function
and immediately calls it. This prevents variable leakage when the script is
sourced by the framework:

```sh
#!/bin/sh
set -e
set -u

__init_toolname() {

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

**Framework-derived (do not set these yourself):**
- `pkg_src_bin` — `$(dirname "$pkg_src_cmd")` — the versioned `bin/` dir
- `pkg_dst_bin` — `$(dirname "$pkg_dst_cmd")` — `~/.local/bin`

### `WEBI_SINGLE`

`WEBI_SINGLE=true` tells the framework to link the binary directly:
`~/.local/bin/cmd → ~/.local/opt/cmd-vX.Y.Z/bin/cmd`

Without it (the default), the framework links the whole directory:
`~/.local/opt/cmd → ~/.local/opt/cmd-vX.Y.Z`

**Set `WEBI_SINGLE=true` for any package that installs a single binary**
— regardless of whether the archive has a subdirectory. Pattern G (SDKs)
is the main case where you do NOT set it, because the whole directory tree
needs to be accessible (e.g. `node/lib/`, `go/src/`).

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

**Pattern A** — binary at archive root (`WEBI_SINGLE=true`):
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

**Pattern B** — binary inside a `tool-{ver}-{triplet}/` subdirectory:
```sh
WEBI_SINGLE=true
pkg_install() {
    mkdir -p "$pkg_src_bin"
    mv ./tool-*/tool "$pkg_src_cmd"
    chmod a+x "$pkg_src_cmd"
}
```

**Pattern C** — like B, plus completions and man pages.
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

**Pattern D** — binary + shared libraries. The entire directory structure
must be preserved. See [`references/PATTERNS.md`](references/PATTERNS.md)
for the ollama and psql examples.

**Pattern E** — FHS layout (archive already has `bin/` and `share/`):
```sh
WEBI_SINGLE=true
pkg_install() {
    mkdir -p "$(dirname "$pkg_src_dir")"
    mv ./tool-*/ "$pkg_src_dir"
}
```

**Pattern F** — binary needs rename (archive name ≠ command name).
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

**Pattern G** — full SDK (do NOT set `WEBI_SINGLE`):
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
    ln -s "$pkg_src_dir" "$pkg_dst"
}
```

---

## 4. Write `install.ps1`

Unlike the shell side, there is no PowerShell framework template — each
`install.ps1` is a self-contained script that handles download, extraction,
and placement itself. The same path conventions apply (opt/bin layout), but
Windows uses `Copy-Item` instead of symlinks for the final `bin/` step.

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

For Pattern A (binary at archive root), change the `Move-Item` line to:
```powershell
Move-Item -Path ".\tool.exe" -Destination "$pkg_src_bin"
```

---

## 5. Check for classification issues

Before writing any scripts, scan the asset list for red flags:

### Non-standard OS/arch names in filenames

The webi classifier recognises most patterns automatically. Watch for:
- `darwin` vs `macos` — both recognised; output normalised to `macos`
- `x86_64` vs `amd64` — both recognised; output normalised to `amd64`
- `aarch64` vs `arm64` — both recognised; output normalised to `arm64`
- `armv7` (missing trailing `l`) — normalised to `armv7l`

These are handled automatically. Only flag them if the asset list contains
something genuinely unusual that the classifier would not recognise.

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

These are automatically filtered by the framework — no action needed:
- `.deb`, `.rpm`, `.snap`, `.AppImage`
- Checksums (`*.sha256`, `*.sha512`, `*.asc`, `*.sig`)
- Source archives (`*-src.tar.gz`, `*.tar.gz` with no OS in name)

---

## Reference files

- [`references/PATTERNS.md`](references/PATTERNS.md) — detailed pattern
  descriptions with real package examples and complete install script snippets
- [`references/ARCHIVE-LAYOUTS.md`](references/ARCHIVE-LAYOUTS.md) — actual
  `tar -t` output for representative packages in each pattern
- [`references/CLASSIFICATION.md`](references/CLASSIFICATION.md) — when and
  how to write variant taggers; non-standard filename conventions
