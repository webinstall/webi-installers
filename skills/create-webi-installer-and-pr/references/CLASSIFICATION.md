# Classification Reference

When to flag classification issues, what the webi classifier does automatically,
and what needs manual annotation.

## Ideal host/target names

Use the simplest stable target name that still distinguishes the build. These
are the common forms to expect in release filenames:

| Toolchain | Host/target form | Examples |
| --- | --- | --- |
| Go | `{os}-{arch}` | `linux-amd64`, `darwin-arm64`, `windows-amd64` |
| GNU | `{arch}-{vendor}-{os}-{libc}` | `x86_64-pc-linux-gnu`, `aarch64-unknown-linux-gnu` |
| Rust | `{arch}-{vendor}-{os}-{env}` | `x86_64-unknown-linux-gnu`, `aarch64-apple-darwin`, `x86_64-pc-windows-msvc` |
| Zig | `{arch}-{os}-{libc}` | `x86_64-linux-gnu`, `aarch64-macos-none`, `x86_64-windows-msvc` |


## What the classifier handles automatically

The webi classifier (`internal/classify/classify.go`) parses asset filenames
using regex patterns and produces canonical `os`, `arch`, `libc`, and `ext`
values. It handles the vast majority of packages with no configuration needed.

### OS recognition
Filenames containing these terms are classified automatically:
- `darwin`, `macos`, `osx`, `apple` → native Go value `darwin`; usually `macos` in legacy cache
- `linux` → `linux`
- `windows`, `win`, `win32`, `win64` → `windows`
- `freebsd`, `openbsd`, `netbsd`, `dragonfly` → respective values
- `sunos`, `illumos`, `solaris` → respective native values; legacy export maps `sunos` to `solaris`
- `.deb`, `.rpm`, `.snap` → `linux` (but dropped from legacy cache)
- `.dmg`, `.app.zip` → native Go value `darwin` (usually `macos` in legacy cache)

### Arch recognition
Filenames containing these terms are classified automatically:
The Go classifier uses native values; legacy export translates some of them
for the Node.js-compatible cache:
- `x86_64`, `amd64`, `64bit`, `x64` → `x86_64` (`amd64` in legacy cache)
- `aarch64`, `arm64` → `aarch64` (`arm64` in legacy cache)
- `armv7`, `armv7l`, `armhf`, `gnueabihf` → `armv7` (usually `armv7l` in legacy cache)
- `armv6`, `armv6l` → `armv6` (usually `armv6l` in legacy cache)
- `i386`, `i686`, `386`, `x86` → `x86`
- `universal`, `universal2` → native universal arch; legacy export folds it to the compatible x86_64/amd64 value

### Format recognition
- `.tar.gz`, `.tar.xz`, `.tar.zst`, `.tar.bz2`, `.zip`, `.7z` → compressed archive
- `.pkg`, `.msi`, `.dmg` → platform installer
- `.exe` → either bare binary or GUI installer (see below)
- No extension in filename → bare binary (ext = `exe` in cache)

### Automatically dropped
These asset types are recognised and excluded without any configuration:
- Checksums: `*.sha256`, `*.sha512`, `*.md5`, `*.sha256sum`
- Signatures and attestations: `*.asc`, `*.sig`, `*.sigstore`, `*.minisig`,
  `*.sbom`, `*.spdx`
- Source archives: files with `source`, `src` in the name but no OS
- Package formats not supported by the Node installer: `.deb`, `.rpm`, `.snap`,
  `.AppImage`, `.apk`


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


### Packages with no OS/arch in filenames

Some packages (rare) release with minimal filename decoration. Examples:
- `tool-v1.2.3.tar.gz` — no OS, no arch
- `tool.tar.gz` — version not even in filename

These are usually source archives (not compiled binaries) and should be
dropped entirely from the release list. If they are compiled binaries for a
specific OS, the package's `releases.conf` needs an `asset_filter` key to
match the right file, plus OS/arch metadata added.


### Non-standard OS naming in filenames

A few upstreams use unusual OS names:
- `sunos` — recognized as `sunos`; legacy export should map it to `solaris`
- `osx` or `macosx` — recognized as `darwin`; legacy export usually calls it `macos`
- `apple-darwin` (Rust triplet) — recognized as `darwin`

If a package uses a genuinely unknown OS string, the classifier will produce
`os = ""` for that asset. Those entries are dropped from the legacy cache.


### Asset filter configuration

If GitHub releases for a package include multiple builds that would otherwise
collide (e.g. `extended` vs non-extended for hugo, or specific project builds
in a monorepo), add to the package's `releases.conf`:

```ini
# Only include assets containing "extended" in the name
asset_filter = extended

# Exclude assets containing "legacy" in the name
exclude = legacy
# `asset_exclude` is accepted as a backwards-compatible alias.
```

These filters run after classification and tagging, before storage and legacy
export.


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


## Vocabulary reference

There are two vocabularies. Go-native storage uses the values from
`internal/buildmeta`; legacy export translates them for the Node.js-compatible
cache.

**Go-native OS**: `darwin`, `linux`, `windows`, `freebsd`, `openbsd`, `netbsd`,
`dragonfly`, `sunos`, `illumos`, `solaris`, `aix`, `android`, `plan9`,
`posix_2017`, `posix_2024`

**Legacy OS**: usually `macos`, `linux`, `windows`, `freebsd`, `openbsd`,
`netbsd`, `dragonfly`, `illumos`, `solaris`, `aix`, `plan9`.

**Go-native arch**: `x86_64`, `x86_64_v2`, `x86_64_v3`, `x86_64_v4`, `aarch64`,
`armv7`, `armv6`, `armv5`, `x86`, `ppc64le`, `ppc64`, `powerpc`, `loong64`,
`riscv64`, `s390x`, `mipsle`, `mips64le`, `mips`, `mips64`, `universal1`,
`universal2`.

**Legacy arch**: commonly `amd64`, `arm64`, `armv7l`, `armv6l`, `x86`,
`mipsle`, `mips64le`, plus the other supported values.

**Libc**: `none` (static/Go/Zig — never empty), `gnu`, `musl`, `msvc`

**Formats**: `tar.gz`, `tar.xz`, `tar.zst`, `tar.bz2`, `tar`, `zip`, `gz`, `xz`,
`zst`, `exe`, `exe.xz`, `7z`, `pkg`, `msi`, `dmg`, `app.zip`, `git`.
Formats have no leading dot in installer metadata; `exe` is also used for bare
binaries.
