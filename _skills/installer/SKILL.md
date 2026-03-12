---
name: installer
description: >
  Create or update install.sh and install.ps1 scripts for a webi package.
  Use when adding a new package to webi-installers, or when an existing
  install script needs to be updated to match a changed archive structure.
  Covers discovering archive layout from GitHub releases, identifying the
  right install pattern (A–I), and writing both the POSIX shell and
  PowerShell scripts that the webi framework calls.
license: MIT
compatibility: Requires git, curl, tar, jq. GitHub API access needed for
  discovery phase. Designed for Claude Code in the webi-installers repo.
metadata:
  author: AJ ONeal
  version: "1.0"
---

# Webi Installer Skill

Write `install.sh` and `install.ps1` for a webi package. These scripts are
called by the webi framework **after** it has already downloaded and verified
the archive — your job is only to unpack and place the files.

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

### Use the webi releases API (fastest)

```sh
# JSON with all releases for a package
curl -s https://webinstall.dev/api/releases/bat.json | jq '.releases[:3]'
```

Each entry has `name` (filename), `version`, `os`, `arch`, `ext`, `download`.

### Or inspect GitHub releases directly

```sh
# List releases for a repo
curl -s "https://api.github.com/repos/sharkdp/bat/releases?per_page=3" \
  | jq '.[0].assets[] | .name'
```

### Inspect what's inside an archive

Download one representative asset and list its contents **without extracting**:

```sh
# tar.gz / tar.xz / tar.zst
curl -fsSL "$DOWNLOAD_URL" | tar -tz

# zip
curl -fsSL "$DOWNLOAD_URL" -o /tmp/pkg.zip && unzip -l /tmp/pkg.zip

# bare binary (no archive)
# Just the binary itself — no unpacking needed (WEBI_SINGLE=true)
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
| **F** | Binary needs rename during install | pathman, yq |
| **G** | Full SDK/toolchain (many files) | go, node, zig, flutter, julia |
| **H** | .NET runtime bundle (flat dir, many DLLs) | pwsh |
| **I** | Multi-binary distribution | dashcore, mutagen |

**Pattern A** is by far the most common (~28 packages). When in doubt,
download the archive and `tar -tz` it before writing a single line of code.

---

## 3. Write `install.sh`

The framework (`_webi/template.sh`) handles: user-agent detection, version
resolution, download, checksum verification, and PATH management. Your script
provides the package-specific part: where to find the binary and how to move it.

### Required variables

```sh
pkg_cmd_name="tool"                              # command name on PATH

pkg_dst_cmd="$HOME/.local/bin/tool"              # final symlink destination
pkg_dst="$pkg_dst_cmd"                           # same as above (or pkg_src_dir for SDKs)

pkg_src_cmd="$HOME/.local/opt/tool-v$WEBI_VERSION/bin/tool"  # versioned binary
pkg_src_dir="$HOME/.local/opt/tool-v$WEBI_VERSION"           # versioned install dir
pkg_src="$pkg_src_cmd"                           # same as above (or pkg_src_dir for SDKs)
```

### Required function

```sh
pkg_install() {
    mkdir -p "$pkg_src_bin"          # $pkg_src_dir/bin
    mv ./tool-*/tool "$pkg_src_cmd"  # pattern-specific — see below
    chmod a+x "$pkg_src_cmd"
}
```

### Recommended function

```sh
pkg_get_current_version() {
    # 'tool --version' output: "tool 1.2.3 (rev abc)"
    # trim to just the version number
    tool --version 2>/dev/null | head -n 1 | cut -d' ' -f2
}
```

### Pattern flag

Set `WEBI_SINGLE=true` when the archive is a flat directory (binary + optional
docs at the root, **no** named subdirectory). This is Pattern A.

```sh
WEBI_SINGLE=true
```

### Skeleton by pattern

**Pattern A** — flat archive, binary at root (set `WEBI_SINGLE=true`):
```sh
WEBI_SINGLE=true
pkg_install() {
    mkdir -p "$pkg_src_bin"
    mv ./tool* "$pkg_src_cmd"
    chmod a+x "$pkg_src_cmd"
}
```

**Pattern B** — binary in `tool-{ver}-{triplet}/` subdirectory:
```sh
pkg_install() {
    mkdir -p "$pkg_src_bin"
    mv ./tool-*/tool "$pkg_src_cmd"
    chmod a+x "$pkg_src_cmd"
}
```

**Pattern C** — like B, plus completions and man pages:
```sh
pkg_install() {
    mkdir -p "$pkg_src_bin"
    mv ./tool-*/tool "$pkg_src_cmd"
    chmod a+x "$pkg_src_cmd"

    # completions (install what exists — not all builds include them)
    if [ -e ./tool-*/completions/tool.bash ]; then
        mkdir -p "$pkg_src_dir/share/bash-completion/completions"
        mv ./tool-*/completions/tool.bash \
            "$pkg_src_dir/share/bash-completion/completions/tool"
    fi
    if [ -e ./tool-*/completions/tool.fish ]; then
        mkdir -p "$pkg_src_dir/share/fish/vendor_completions.d"
        mv ./tool-*/completions/tool.fish \
            "$pkg_src_dir/share/fish/vendor_completions.d/tool.fish"
    fi
    if [ -e ./tool-*'/completions/_tool' ]; then
        mkdir -p "$pkg_src_dir/share/zsh/site-functions"
        mv './tool-*/completions/_tool' \
            "$pkg_src_dir/share/zsh/site-functions/_tool"
    fi

    # man page
    if [ -e ./tool-*/tool.1 ]; then
        mkdir -p "$pkg_src_dir/share/man/man1"
        mv ./tool-*/tool.1 "$pkg_src_dir/share/man/man1/tool.1"
    fi
}
```

**Pattern E** — FHS layout (archive already has `bin/` and `share/`):
```sh
pkg_install() {
    mkdir -p "$(dirname "$pkg_src_dir")"
    mv ./tool-*/ "$pkg_src_dir"
}
# bin/tool is already at the right relative path; no chmod needed
```

**Pattern F** — binary needs rename:
```sh
pkg_install() {
    mkdir -p "$pkg_src_bin"
    mv ./tool_linux_amd64 "$pkg_src_cmd"   # or whatever the archive names it
    chmod a+x "$pkg_src_cmd"
}
```

**Pattern G** — full SDK:
```sh
pkg_src="$pkg_src_dir"    # NOTE: pkg_src points to the directory, not a binary
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

PowerShell scripts are more explicit — they handle download, extract, and
placement inline. Windows uses `Copy-Item` instead of symlinks for the final
`bin/` step.

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

        # Move binary into place
        Write-Output "Install Location: $pkg_src_cmd"
        New-Item "$pkg_src_bin" -ItemType Directory -Force | Out-Null
        Move-Item -Path ".\tool-*\tool.exe" -Destination "$pkg_src_bin"
    Pop-Location
}

# "Symlink" on Windows = copy to bin/
Write-Output "Copying into '$pkg_dst_cmd' from '$pkg_src_cmd'"
Remove-Item -Path "$pkg_dst_cmd" -Recurse -ErrorAction Ignore | Out-Null
New-Item "$pkg_dst_bin" -ItemType Directory -Force | Out-Null
Copy-Item -Path "$pkg_src" -Destination "$pkg_dst" -Recurse
```

Adjust the `Move-Item` path glob to match the archive's actual subdirectory
name (or remove the subdirectory if Pattern A).

---

## 5. Check for classification issues

Before writing any scripts, scan the asset list for red flags:

### Non-standard OS/arch names in filenames

The webi classifier recognises most patterns automatically. Watch for:
- `darwin` vs `macos` — Go classifier uses `darwin`; legacy cache uses `macos`
- `x86_64` vs `amd64` — both recognised; output normalised to `amd64`
- `aarch64` vs `arm64` — both recognised; output normalised to `arm64`
- `armv7` (missing trailing `l`) — should be `armv7l`

These are handled automatically during classification. Only flag them if the
asset list contains something genuinely unusual.

### Variant assets needing tags

Flag if you see:
- **GPU variants**: `*-rocm*`, `*-cuda*`, `*-vulkan*` alongside a baseline build
- **Windows installer**: `*Setup.exe` or `*Install.exe` alongside a bare `*.exe`
- **Framework-dependent .NET**: `*-fxdependent*` vs self-contained
- **AppImage**: `*.AppImage` — not supported by the Node installer
- **Electron app**: `*.dmg` or `*.AppImage` that is a full GUI app, not a CLI

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
  descriptions with real package examples and install script snippets
- [`references/ARCHIVE-LAYOUTS.md`](references/ARCHIVE-LAYOUTS.md) — actual
  `tar -t` output for representative packages in each pattern
- [`references/CLASSIFICATION.md`](references/CLASSIFICATION.md) — when and
  how to write variant taggers; non-standard filename conventions
