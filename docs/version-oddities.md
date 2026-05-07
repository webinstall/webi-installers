# Version & Release Oddities

Non-standard version formats and tag prefixes that affect parsing, sorting,
and classification. The Go classifier and `internal/lexver` must handle all
of these.

## Non-Numeric Tag Prefixes

| Package | Raw Tag | Cleaned | Transform |
|---------|---------|---------|-----------|
| lf | `r21` | `0.21.0` | `r` prefix → prepend `0.` |
| bun | `bun-v1.0.0` | `1.0.0` | Strip `bun-` prefix |
| jq | `jq-1.7` | `1.7` | Strip `jq-` prefix |
| watchexec | `cli-v1.2.3` | `1.2.3` | Strip `cli-` prefix |
| ffmpeg | `b6.0` | `6.0` | Strip `b` prefix |

## Underscore-Delimited Tags

| Package | Raw Tag | Cleaned | Transform |
|---------|---------|---------|-----------|
| postgres | `REL_17_0` | `17.0` | Strip `REL_`, replace `_` with `.` |
| psql | `REL_17_0` | `17.0` | Same as postgres |

## Platform Suffix in Version

| Package | Raw Tag | Cleaned | Transform |
|---------|---------|---------|-----------|
| git (Windows) | `2.41.0.windows.1` | `2.41.0` | Strip `.windows.N` suffix |

## 4-Part Versions

| Package | Example | Notes |
|---------|---------|-------|
| chromedriver | `121.0.6120.0` | Google Chrome's versioning |
| gpg | `2.2.19.0` | 4th segment is build metadata |

## Date-Based Versions

| Package | Notes |
|---------|-------|
| atomicparsley | Date-based version strings |

## Complex Pre-Release Formats

| Package | Example | Notes |
|---------|---------|-------|
| flutter | `2.3.0-16.0.pre` | Extra dots and numeric segments |
| iterm2 | `iTerm2_3_5_0beta17` | Underscores, beta attached → `3.5.0-beta17` |

## Channel Detection

- Node.js: odd major = "current" not LTS (v15, v17, v19, v21, v23)
- Go: `go` prefix stripped (`go1.23.6` → `1.23.6`)
- Terraform: `-alpha`, `-beta`, `-rc` suffixes → beta channel

## Directory Symlinks (Aliases)

These are directory-level symlinks. They share all files (including
releases.conf) with their target automatically.

```
msvc-runtime    → vcruntime
msvcruntime     → vcruntime
rust.vim        → vim-rust
vc-redist       → vcruntime
vc-runtime      → vcruntime
vc_redist       → vcruntime
vcredist        → vcruntime
vcruntime140    → vcruntime
vim-essential   → vim-essentials
vim-mouse       → vim-gui
vps-myip        → myip
xcode-cli       → commandlinetools
```
