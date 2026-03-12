# Classification Reference

When to flag classification issues, what the webi classifier does automatically,
and what needs manual annotation.

---

## What the classifier handles automatically

The webi classifier (`internal/classify/classify.go`) parses asset filenames
using regex patterns and produces canonical `os`, `arch`, `libc`, and `ext`
values. It handles the vast majority of packages with no configuration needed.

### OS recognition
Filenames containing these terms are classified automatically:
- `darwin`, `macos`, `osx`, `apple` → `macos` in legacy cache
- `linux` → `linux`
- `windows`, `win`, `win32`, `win64` → `windows`
- `freebsd`, `openbsd`, `netbsd`, `dragonfly` → respective values
- `.deb`, `.rpm`, `.snap` → `linux` (but dropped from legacy cache)
- `.dmg`, `.app.zip` → `macos`

### Arch recognition
Filenames containing these terms are classified automatically:
- `x86_64`, `amd64`, `64bit`, `x64` → `amd64`
- `aarch64`, `arm64` → `arm64`
- `armv7`, `armv7l`, `armhf`, `gnueabihf` → `armv7l`
- `armv6`, `armv6l` → `armv6l`
- `i386`, `i686`, `386`, `x86` → `x86`
- `universal`, `universal2` → `amd64` (fat binary; arm64 falls back to this)

### Format recognition
- `.tar.gz`, `.tar.xz`, `.tar.zst`, `.tar.bz2`, `.zip`, `.7z` → compressed archive
- `.pkg`, `.msi`, `.dmg` → platform installer
- `.exe` → either bare binary or GUI installer (see below)
- No extension in filename → bare binary (ext = `exe` in cache)

### Automatically dropped
These asset types are recognised and excluded without any configuration:
- Checksums: `*.sha256`, `*.sha512`, `*.md5`, `*.sha256sum`
- Signatures: `*.asc`, `*.sig`, `*.cosign`, `*.sbom`
- Source archives: files with `source`, `src` in the name but no OS
- Package formats not supported by the Node installer: `.deb`, `.rpm`, `.snap`,
  `.AppImage`, `.apk`

---

## When you need to add configuration

### Variant assets

A **variant** is a secondary build that serves the same OS/arch as a baseline
build but requires different hardware or runtime support. The Node.js installer
can't choose between variants — it only knows OS, arch, and libc. Variants
must be tagged and then excluded at export time.

**Common variants and how to identify them**:

| Variant | Filename pattern | Notes |
|---------|-----------------|-------|
| CUDA (GPU) | `*-cuda*`, `*cuda12*` | NVIDIA GPU support |
| ROCm (GPU) | `*-rocm*` | AMD GPU support |
| Vulkan | `*-vulkan*` | Cross-vendor GPU |
| AppImage | `*.AppImage` | Linux sandboxed app |
| .NET fxdependent | `*-fxdependent*` | Requires .NET runtime |
| Windows installer | `*Setup.exe`, `*Install.exe` | GUI installer, not the binary |

**Rule**: if there are multiple assets for the same OS/arch combination and
they serve the same users differently, they need variant tags. The baseline
(most widely compatible) build should be kept; variants should be tagged and
excluded.

**Example**: ollama publishes for linux/amd64:
- `ollama-linux-amd64.tar.zst` — baseline (CPU + any GPU auto-detected)
- `ollama-linux-amd64-rocm.tar.zst` — ROCm variant
- `ollama-linux-amd64-jetpack6.tar.zst` — NVIDIA Jetson variant

Only the baseline is useful via webi. The ROCm and Jetpack builds should be
tagged as variants and excluded.

---

### Windows .exe: bare binary vs GUI installer

`.exe` assets are ambiguous — they could be:
1. A bare binary (the tool itself, run from command line)
2. A GUI installer (runs a setup wizard, not useful for webi)

**How to tell**:
- GUI installer: filename contains `Setup`, `Install`, `Installer`, `inno`, `nsis`
- GUI installer: the tool also has a `.zip` or `.tar.gz` for Windows
- Bare binary: filename matches the tool name with minimal decoration

**When you see both**, the `.zip`/archive build is what webi uses. The `.exe`
installer should be tagged as a variant (`installer`) so it's excluded.

**When there's only a `.exe`** (no archive), it's probably the bare binary.
Test by downloading and running it — a bare binary runs immediately.

---

### Packages with no OS/arch in filenames

Some packages (rare) release with minimal filename decoration. Examples:
- `tool-v1.2.3.tar.gz` — no OS, no arch
- `tool.tar.gz` — version not even in filename

These are usually source archives (not compiled binaries) and should be
dropped entirely from the release list. If they are compiled binaries for a
specific OS, the releases.js config needs an `asset_filter` key to match the
right file, plus OS/arch metadata added.

---

### Non-standard OS naming in filenames

A few upstreams use unusual OS names:
- `sunos` — should map to `solaris` (the webi classifier does this)
- `osx` or `macosx` — recognised as `macos`
- `apple-darwin` (Rust triplet) — recognised as `macos`

If a package uses a genuinely unknown OS string, the classifier will produce
`os = ""` for that asset. Those entries are dropped from the legacy cache.

---

### Asset filter configuration

If GitHub releases for a package include multiple builds that would otherwise
collide (e.g. `extended` vs non-extended for hugo, or specific project builds
in a monorepo), add to the package's `releases.conf`:

```ini
# Only include assets containing "extended" in the name
asset_filter = extended

# Exclude assets containing "legacy" in the name
asset_exclude = legacy
```

These filters run before classification.

---

## Quick checklist when inspecting a new package

1. **Look at the latest 2–3 releases** on GitHub. Note all asset filenames.
2. **Find the "standard" builds** — the ones a normal user would download for
   their OS. Usually there are ≤4 per OS (amd64, arm64, x86, armv7l).
3. **Check for extras**:
   - Are there GPU-specific builds for the same OS/arch? → variant
   - Are there `.exe` installer files alongside a `.zip`? → variant
   - Are there `.deb`/`.rpm`/`.AppImage`? → auto-dropped, no action needed
   - Does the Windows build have no archive and only a bare `.exe`? → fine
4. **Check OS/arch naming** — does the filename use standard terms, or
   something unusual that might confuse the classifier?
5. **Check format changes** — do old releases use a different archive type
   or directory layout than recent ones? The install script may need to
   handle both.

---

## Canonical vocabulary reference

All cache output must use exactly these values.

**OS**: `macos`, `linux`, `windows`, `freebsd`, `openbsd`, `netbsd`,
`dragonfly`, `aix`, `illumos`, `plan9`, `solaris`

**Arch**:
- `amd64` (not `x86_64`)
- `arm64` (not `aarch64`)
- `armv7l` (not `armv7` — the `l` stands for little-endian; `uname -m` reports `armv7l`)
- `armv6l` (not `armv6`)
- `x86` (not `i386`, `i686`, `386`)
- `mipsle` (not `mipsel`)
- `mips64le` (not `mips64el`)
- Other: `arm`, `ppc64le`, `ppc64`, `loong64`, `riscv64`, `s390x`, `mips`, `mips64`

**Libc**: `none` (static/Go/Zig — never empty), `gnu`, `musl`, `msvc`

**Ext**: `tar.gz`, `tar.xz`, `zip`, `exe`, `7z`, `pkg`, `msi`
(no leading dot; `exe` for bare binaries with no file extension)
