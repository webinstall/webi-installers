# Installer Archive Patterns

Every package falls into one of these archive structure patterns. When writing
or modifying an `install.sh`, identify the pattern first — it determines the
extraction and installation strategy.

## Pattern A: Bare Binary in Archive

Archive contains the binary (and maybe LICENSE/README) at the top level.

Examples: awless, caddy, cilium, curlie, dashmsg, deno, dotenv, dotenv-linter,
ffuf, fzf, gitdeploy, gprox, grype, hugo, hugo-extended, k9s, keypairs, koji,
lf, monorel, ots, runzip, sclient, sqlc, sqlpkg, sttr, terraform, uuidv7, xcaddy

Install: extract, move binary to `~/.local/opt/{pkg}-{ver}/bin/{binary}`, symlink.

## Pattern B: Subdirectory with Binary Only

Archive contains a version-named directory wrapping the binary and docs.

Examples: delta, hexyl, kubectx, kubens, shellcheck, trip, xsv

Typical directory naming: `{tool}-{ver}-{triplet}/`

Install: extract, find binary in subdirectory, move to opt, symlink.

Special cases:
- `pathman`: bare binary named with full release tag (needs rename)
- `yq`: binary named with platform suffix `yq_linux_amd64` (needs rename)

## Pattern C: Binary + Completions + Man Pages

Archive includes shell completions and/or man pages alongside the binary.

| Package | Completions Dir | Man Page |
|---------|----------------|----------|
| bat | `autocomplete/` | `bat.1` |
| fd | `autocomplete/{fd.bash,.fish,_fd}` | `fd.1` |
| goreleaser | `completions/{.bash,.fish,.zsh}` | `manpages/*.1.gz` |
| lsd | `autocomplete/{lsd.bash-completion,.fish,_lsd}` | `lsd.1` |
| rg | `complete/{rg.bash,.fish,_rg}` | `doc/rg.1` |
| sd | `completions/{sd.bash,.fish,_sd}` | `sd.1` |
| watchexec | `completions/{bash,fish,zsh}` | `watchexec.1` |
| zoxide | `completions/{zoxide.bash,.fish,_zoxide}` | `man/man1/zoxide*.1` |

Install: extract, install binary, install completions to standard dirs, install
man pages. Completion naming varies: `autocomplete/`, `completions/`, `complete/`.

## Pattern D: Binary + Libraries

Complex packages that bundle shared libraries.

| Package | Layout |
|---------|--------|
| ollama (Linux) | `bin/ollama` + `lib/ollama/{cuda_v12,cuda_v13,vulkan}/` |
| pg/postgres/psql | `bin/psql` + `lib/{libpq,libz,...}.so` + `include/` |
| sass | `dart-sass/sass` (wrapper) + `dart-sass/src/{dart,sass.snapshot}` |
| syncthing | `syncthing-{triplet}-{ver}/syncthing` + `etc/{systemd,...}/` |
| xz | `xz-{ver}-{triplet}/xz` + `xz-{ver}-{triplet}/unxz` |

Install: extract entire directory tree into opt, symlink binary.

## Pattern E: FHS-like Layout (bin/ + share/)

Archive already follows standard layout.

| Package | Layout |
|---------|--------|
| gh | `gh_{ver}_{os}_{arch}/bin/gh` + `share/man/man1/*.1` |
| pandoc | `pandoc-{ver}/bin/{pandoc,...}` + `share/man/man1/*.1.gz` |

Install: extract directly into opt (already correct layout).

## Pattern G: Full SDK/Toolchain

Self-contained toolchain with compiler, runtime, standard library.

| Package | Layout |
|---------|--------|
| cmake | `cmake-{ver}-{os}-{arch}/bin/{cmake,ctest,...}` + `share/` + `man/` |
| tinygo | `tinygo/bin/tinygo` + `tinygo/src/` + `tinygo/targets/` |
| go | `go/bin/{go,gofmt}` + `go/src/` + `go/pkg/` |
| zig | `zig-{os}-{arch}-{ver}/zig` + `lib/` |
| flutter | `flutter/bin/flutter` + full SDK |
| julia | `julia-{ver}/bin/julia` + full SDK |
| node | `node-{ver}-{os}-{arch}/bin/{node,npm,npx}` + `lib/` |

Install: extract entire tree into `~/.local/opt/{pkg}-{ver}/`, symlink `bin/*`.

## Pattern H: .NET Runtime Bundle

Flat archive with hundreds of DLLs.

Example: pwsh — `pwsh` binary + `*.dll` + locale dirs

Install: extract entire directory into opt, symlink primary binary.

## Pattern I: Multi-Binary Distribution

Archive contains multiple related binaries + libs.

| Package | Layout |
|---------|--------|
| dashcore | `dashcore-{ver}/bin/{dashd,dash-cli,...}` + `lib/` + `share/man/` |
| mutagen | `mutagen` + `mutagen-agents.tar.gz` (embedded agent archive) |

Install: extract into opt, symlink primary binary.

## Format Changes Over Time

Most packages have stable formats. Notable structural changes:

| Package | When | Change |
|---------|------|--------|
| sd | 2023 | zip → tar.gz, added completions + man page |
| ollama | 2025-2026 | bare binary → no GitHub release → tar.zst with lib/ |
| deno | 2020-2021 | .gz (gzipped binary) → .zip |
| hugo | 2017-2018 | zip → tar.gz; 2024: macOS → .pkg only |
| gh | 2024 | darwin: tar.gz → .pkg |
| sclient | 2023 | tar.gz → tar.xz |
| watchexec | 2019-2020 | tar.gz → tar.xz |
