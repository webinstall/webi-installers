# Install Patterns Reference

Ten named patterns cover the full range of webi packages. **idealist** is by far
the most common. Check `tar -tz $ARCHIVE` before writing any code.

| Class | Description |
| --- | --- |
| waif | Single bare or compressed binary |
| idealist | Single binary at archive root |
| prestige | One wrapper directory, one binary |
| pseudos | Binary needs renaming |
| caravan | Binary with shared libraries |
| completionist | FHS layout with files in place |
| heretic | Gang's all there, but in a bespoke, convention-defying layout |
| legion | Full SDK or monolith |
| pantheon | Multi-binary distribution |

## waif — Single binary, optionally compressed

There is no archive containing multiple files. The download is one bare binary,
or one binary wrapped in a supported single-file compression format. The
framework moves or inflates it, then applies `chmod a+x`.

Representative packages: jq, shfmt.

**install.sh**:
```sh
WEBI_SINGLE=true

pkg_get_current_version() {
    jq --version 2>/dev/null | head -n 1 | sed 's:^jq-::'
}
```

A custom `pkg_install()` is usually not needed. The framework's default install
handles the extracted file.


## idealist — Bare binary at archive root

The archive extracts directly to the current directory with no wrapper
subdirectory. Binary (and optional LICENSE/README) is at the top level.

**Set `WEBI_SINGLE=true`** — tells the framework to link the binary file
directly (`~/.local/bin/cmd → ~/.local/opt/cmd-vX/bin/cmd`) rather than
linking the versioned directory.

Representative packages: caddy, fzf, k9s, terraform, sttr, lf, monorel,
awless, cilium, curlie, dashmsg, dotenv, dotenv-linter, ffuf,
gitdeploy, gprox, grype, hugo, keypairs, koji, ots, runzip, sclient,
sqlc, sqlpkg, uuidv7, xcaddy, deno

**install.sh**:
```sh
pkg_cmd_name="caddy"
WEBI_SINGLE=true

pkg_dst_cmd="$HOME/.local/bin/caddy"
pkg_dst="$pkg_dst_cmd"
pkg_src_cmd="$HOME/.local/opt/caddy-v$WEBI_VERSION/bin/caddy"
pkg_src_dir="$HOME/.local/opt/caddy-v$WEBI_VERSION"
pkg_src="$pkg_src_cmd"

pkg_install() {
    mkdir -p "$pkg_src_bin"
    mv ./"$pkg_cmd_name"* "$pkg_src_cmd"
    chmod a+x "$pkg_src_cmd"
}

pkg_get_current_version() {
    caddy version 2>/dev/null | head -n 1 | cut -d' ' -f1 | sed 's:^v::'
}
```

**install.ps1** key lines:
```powershell
# No subdirectory — binary is at the top level of the archive
Move-Item -Path ".\caddy.exe" -Destination "$pkg_src_bin"
```


## prestige — Binary inside a version/triplet subdirectory

Archive extracts to a single directory named with the version and/or
platform triplet. Binary (and docs) live inside that directory.

Representative packages: bun, delta, hexyl, shellcheck, trip, xsv, kubectx, kubens

**Subdirectory naming conventions seen in the wild**:
- `tool-{ver}-{triplet}/` — most Rust tools (delta, shellcheck, xsv)
- `tool-{ver}/` — simpler version-only dirs
- flat (no dir) — kubectx/kubens use flat archives and are closer to idealist

**install.sh**:
```sh
pkg_cmd_name="delta"
# WEBI_SINGLE not set (or false)

pkg_dst_cmd="$HOME/.local/bin/delta"
pkg_dst="$pkg_dst_cmd"
pkg_src_cmd="$HOME/.local/opt/delta-v$WEBI_VERSION/bin/delta"
pkg_src_dir="$HOME/.local/opt/delta-v$WEBI_VERSION"
pkg_src="$pkg_src_cmd"

pkg_install() {
    mkdir -p "$pkg_src_bin"
    mv ./delta-*/delta "$pkg_src_cmd"
    chmod a+x "$pkg_src_cmd"
}

pkg_get_current_version() {
    delta --version 2>/dev/null | head -n 1 | cut -d' ' -f2
}
```

**install.ps1** key lines:
```powershell
Move-Item -Path ".\delta-*\delta.exe" -Destination "$pkg_src_bin"
```


## heretic — Gang's all there, but in a bespoke, convention-defying layout

Same as prestige but the archive also contains shell completions and/or man pages
worth installing. A new installer should preserve these extra files when they
are useful, even though several older webi scripts currently install only the
main binary.

Representative packages: bat, fd, lsd, rg/ripgrep, sd, watchexec, zoxide

Note: goreleaser has a flat archive (idealist layout) but with completions at
the archive root. See the goreleaser entry in the real archive layouts below.

**Completion directory name varies by package**:
- `completions/` — sd, watchexec, zoxide
- `autocomplete/` — bat, fd, lsd
- `complete/` — rg/ripgrep

**Completion filename conventions**:
- Bash: `tool.bash`, `tool.bash-completion`, `_tool.bash`
- Fish: `tool.fish`
- Zsh: `_tool`
- PowerShell: `_tool.ps1`, `tool.ps1`

**Man page location varies**:
- `tool.1` at subdirectory root — sd, bat, fd, lsd
- `doc/tool.1` — rg/ripgrep
- `man/man1/tool.1` — zoxide (deepest path)

**install.sh** (recommended full install for rg):
```sh
pkg_cmd_name="rg"

pkg_dst_cmd="$HOME/.local/bin/rg"
pkg_dst="$pkg_dst_cmd"
pkg_src_cmd="$HOME/.local/opt/rg-v$WEBI_VERSION/bin/rg"
pkg_src_dir="$HOME/.local/opt/rg-v$WEBI_VERSION"
pkg_src="$pkg_src_cmd"

pkg_install() {
    mkdir -p "$pkg_src_bin"
    mv ./ripgrep-*/rg "$pkg_src_cmd"
    chmod a+x "$pkg_src_cmd"

    # bash completion
    if test -e ./ripgrep-*/complete/rg.bash; then
        mkdir -p "$pkg_src_dir/share/bash-completion/completions"
        mv ./ripgrep-*/complete/rg.bash \
            "$pkg_src_dir/share/bash-completion/completions/rg"
    fi
    # fish completion
    if test -e ./ripgrep-*/complete/rg.fish; then
        mkdir -p "$pkg_src_dir/share/fish/vendor_completions.d"
        mv ./ripgrep-*/complete/rg.fish \
            "$pkg_src_dir/share/fish/vendor_completions.d/rg.fish"
    fi
    # zsh completion
    if test -e ./ripgrep-*/complete/_rg; then
        mkdir -p "$pkg_src_dir/share/zsh/site-functions"
        mv ./ripgrep-*/complete/_rg \
            "$pkg_src_dir/share/zsh/site-functions/_rg"
    fi
    # man page
    if test -e ./ripgrep-*/doc/rg.1; then
        mkdir -p "$pkg_src_dir/share/man/man1"
        mv ./ripgrep-*/doc/rg.1 "$pkg_src_dir/share/man/man1/rg.1"
    fi
}

pkg_get_current_version() {
    rg --version 2>/dev/null | head -n 1 | cut -d' ' -f2
}
```

**Note**: Completion paths in completions/man install are best-effort
— use `if test -e ...` guards so the script still works on older releases
that didn't include them.


## caravan — Binary + shared libraries

The package bundles shared libraries alongside the binary. The entire
directory tree must be preserved.

Representative packages: ollama (Linux), psql/postgres, sass (Dart VM),
syncthing, xz

**install.sh**:
```sh
pkg_cmd_name="ollama"

pkg_dst_cmd="$HOME/.local/bin/ollama"
pkg_dst="$pkg_dst_cmd"
pkg_src_cmd="$HOME/.local/opt/ollama-v$WEBI_VERSION/bin/ollama"
pkg_src_dir="$HOME/.local/opt/ollama-v$WEBI_VERSION"
pkg_src="$pkg_src_cmd"

pkg_install() {
    mkdir -p "$(dirname "$pkg_src_dir")"
    # Archive already has bin/ and lib/ layout
    mv ./bin "$pkg_src_dir/bin"
    mv ./lib "$pkg_src_dir/lib"
}
```

For psql (archive has a `psql-{ver}-{triplet}/` wrapper dir):
```sh
pkg_install() {
    mkdir -p "$(dirname "$pkg_src_dir")"
    mv ./psql-*/ "$pkg_src_dir"
}
```


## completionist — FHS-like layout

Archive already follows `bin/`, `share/man/`, `share/doc/` hierarchy.
Extract the whole thing directly into the versioned opt directory.

Representative packages: gh (GitHub CLI), pandoc

**install.sh**:
```sh
pkg_cmd_name="gh"

pkg_dst_cmd="$HOME/.local/bin/gh"
pkg_dst="$pkg_dst_cmd"
pkg_src_cmd="$HOME/.local/opt/gh-v$WEBI_VERSION/bin/gh"
pkg_src_dir="$HOME/.local/opt/gh-v$WEBI_VERSION"
pkg_src="$pkg_src_cmd"

pkg_install() {
    mkdir -p "$(dirname "$pkg_src_dir")"
    # Preserve bin/, share/man/, and any other files in the FHS tree.
    mv ./gh_*/ "$pkg_src_dir"
}

pkg_get_current_version() {
    gh --version 2>/dev/null | head -n 1 | cut -d' ' -f3
}
```

No `chmod` needed — binary is already executable inside the archive.


## pseudos — Binary needs rename

Binary in the archive doesn't match the expected command name.

Representative packages: pathman (`pathman-v0.6.0-linux-amd64_v1` → `pathman`),
yq (`yq_linux_amd64` → `yq`)

**install.sh**:
```sh
pkg_cmd_name="yq"
WEBI_SINGLE=true

pkg_dst_cmd="$HOME/.local/bin/yq"
pkg_dst="$pkg_dst_cmd"
pkg_src_cmd="$HOME/.local/opt/yq-v$WEBI_VERSION/bin/yq"
pkg_src_dir="$HOME/.local/opt/yq-v$WEBI_VERSION"
pkg_src="$pkg_src_cmd"

pkg_install() {
    mkdir -p "$pkg_src_bin"
    # Binary is named yq_linux_amd64 (or yq_darwin_amd64 etc)
    mv ./yq_* "$pkg_src_cmd"
    chmod a+x "$pkg_src_cmd"
}
```


## legion — Full SDK / toolchain

Archive contains a complete runtime or SDK (hundreds to thousands of files).
The entire tree goes into opt; multiple binaries are linked from `bin/`.

Representative packages: go, node, zig, flutter, julia, cmake, tinygo

**install.sh** (node as example):
```sh
pkg_cmd_name="node"
# NOTE: pkg_src points to the directory, not a binary

pkg_dst_cmd="$HOME/.local/bin/node"
pkg_dst="$HOME/.local/opt/node"   # versioned-dir symlink target

pkg_src_cmd="$HOME/.local/opt/node-v$WEBI_VERSION/bin/node"
pkg_src_dir="$HOME/.local/opt/node-v$WEBI_VERSION"
pkg_src="$pkg_src_dir"            # pkg_src = the directory

pkg_install() {
    mkdir -p "$(dirname "$pkg_src")"
    mv ./node-*/ "$pkg_src"
}

pkg_link() {
    rm -f "$pkg_dst"
    ln -s "$pkg_src" "$pkg_dst"
}

pkg_get_current_version() {
    node --version 2>/dev/null | head -n 1 | sed 's:^v::'
}
```


## pwsh — .NET runtime bundle (heretic)

Flat directory with one binary and hundreds of `.dll` files. The entire
directory must be preserved. Like legion (SDK) in structure — the
versioned directory is the package root, with the binary directly inside
(no `bin/` subdirectory). A `pkg_link()` creates the unversioned symlink.

Representative packages: pwsh (PowerShell Core)

**install.sh**:
```sh
pkg_cmd_name="pwsh"

# note: binary is at pkg_src_dir root, no bin/ subdirectory
pkg_src_cmd="$HOME/.local/opt/pwsh-v$WEBI_VERSION/pwsh"
pkg_src_dir="$HOME/.local/opt/pwsh-v$WEBI_VERSION"
pkg_src="$pkg_src_dir"

pkg_dst_cmd="$HOME/.local/opt/pwsh/pwsh"
pkg_dst="$HOME/.local/opt/pwsh"

pkg_install() {
    # Archive extracts flat — move all contents into the versioned dir
    mkdir -p "$pkg_src_dir"
    mv ./* "$pkg_src_dir"
    chmod a+x "$pkg_src_cmd"
}

pkg_link() {
    rm -rf "$pkg_dst"
    ln -s "$pkg_src" "$pkg_dst"
}
```


## pantheon — Multi-binary distribution

Archive contains multiple related binaries. Install the primary one and
link only that.

Representative packages: dashcore (dashd + dash-cli + dash-qt + ...),
mutagen (mutagen + mutagen-agents.tar.gz)

**install.sh** (dashcore-style):
```sh
pkg_cmd_name="dashd"

pkg_dst_cmd="$HOME/.local/bin/dashd"
pkg_dst="$pkg_dst_cmd"
pkg_src_cmd="$HOME/.local/opt/dashcore-v$WEBI_VERSION/bin/dashd"
pkg_src_dir="$HOME/.local/opt/dashcore-v$WEBI_VERSION"
pkg_src="$pkg_src_cmd"

pkg_install() {
    mkdir -p "$(dirname "$pkg_src_dir")"
    mv ./dashcore-*/ "$pkg_src_dir"
}
```


## Choosing between patterns

```
Download contains one binary, bare or in supported single-file compression?
  → waif  (set WEBI_SINGLE=true)

Archive root contains a single binary (or binary + docs)?
  → idealist  (set WEBI_SINGLE=true)

Archive has a named subdirectory wrapping the binary?
  ├─ Binary only inside subdir?         → prestige
  ├─ Binary + completions/man pages?    → heretic
  └─ Binary + shared libraries (.so)?  → caravan

Archive already has bin/ and share/ layout?
  → completionist

Binary name doesn't match the command name?
  → pseudos  (rename during install)

Archive is a full SDK (compiler, runtime, stdlib)?
  → legion  (pkg_src = pkg_src_dir)

Flat directory with many DLLs (.NET)?
  → heretic

Multiple binaries for a single distributed system?
  → pantheon
```

# Real archive layouts

Actual `tar -t` / `unzip -l` output for representative packages.
Use these to calibrate your eye for what each pattern looks like.

## waif examples

There is no `tar -t` listing for the bare form. Check the release filename and
format metadata instead. For example, shfmt publishes names such as
`shfmt_v3.14.1_linux_amd64` directly.


## idealist examples

### caddy 2.9.1 — linux/amd64 tar.gz
```
.
├── caddy
├── LICENSE
└── README.md
```
Binary `caddy` is at the top level. Set `WEBI_SINGLE=true`.

### fzf 0.70.0 — linux/amd64 tar.gz
```
.
└── fzf
```
Minimal — just the binary.

### terraform 1.9.8 — linux/amd64 zip
```
.
├── terraform
└── LICENSE.txt
```
Zip archive but same flat layout.

### k9s — linux/amd64 tar.gz
```
.
├── k9s
├── LICENSE
└── README.md
```


## prestige examples

### delta 0.18.2 — linux/amd64 tar.gz
```
.
└── delta-0.18.2-x86_64-unknown-linux-musl
    ├── delta
    ├── LICENSE
    └── README.md
```
Glob to move: `./delta-*/delta`

### shellcheck 0.10.0 — linux/x86_64 tar.xz
```
.
└── shellcheck-v0.10.0
    ├── shellcheck
    ├── LICENSE.txt
    └── README.txt
```
Glob to move: `./shellcheck-*/shellcheck`

### xsv 0.13.0 — linux/x86_64 tar.gz
```
.
└── xsv-0.13.0-x86_64-unknown-linux-musl
    ├── xsv
    └── UNLICENSE
```


## heretic examples

### rg/ripgrep 14.1.1 — linux/amd64 tar.gz
```
.
└── ripgrep-14.1.1-x86_64-unknown-linux-musl
    ├── rg
    ├── complete
    │   ├── _rg
    │   ├── _rg.ps1
    │   ├── rg.bash
    │   └── rg.fish
    ├── doc
    │   ├── rg.1
    │   ├── FAQ.md
    │   └── GUIDE.md
    ├── CHANGELOG.md
    ├── LICENSE-MIT
    └── README.md
```
Note: completions are in `complete/` (not `completions/`). Man page is `doc/rg.1`.

### sd 1.1.0 — linux/x86_64 tar.gz
```
.
└── sd-v1.1.0-x86_64-unknown-linux-musl
    ├── sd
    ├── sd.1
    ├── completions
    │   ├── sd.bash
    │   ├── sd.elv
    │   ├── sd.fish
    │   ├── _sd
    │   └── _sd.ps1
    ├── CHANGELOG.md
    ├── LICENSE
    └── README.md
```
Note: man page `sd.1` is at subdirectory root. Completions in `completions/`.

### bat 0.26.1 — linux/amd64 tar.gz
```
.
└── bat-v0.26.1-x86_64-unknown-linux-musl
    ├── bat
    ├── bat.1
    ├── autocomplete
    │   ├── bat.bash
    │   ├── bat.fish
    │   └── bat.zsh
    ├── LICENSE-APACHE
    ├── LICENSE-MIT
    └── README.md
```
Note: completions in `autocomplete/` (not `completions/`). Zsh file is `bat.zsh` not `_bat`.

### goreleaser — linux/amd64 tar.gz
```
.
├── goreleaser
├── completions
│   ├── goreleaser.bash
│   ├── goreleaser.fish
│   └── goreleaser.zsh
├── manpages
│   └── goreleaser.1.gz
├── LICENSE.md
└── README.md
```
Note: goreleaser uses idealist layout (binary at root, no subdirectory)
but includes completions and a gzipped man page. Set `WEBI_SINGLE=true`;
move completions and man page after the binary.


## caravan examples

### ollama 0.17.7 — linux/amd64 tar.zst
```
.
├── bin
│   └── ollama
├── lib
│   └── ollama
│       ├── libggml-base.so
│       ├── libggml-cpu-alderlake.so
│       ├── libggml-cpu-haswell.so
│       ├── libggml-cpu-icelake.so
│       ├── libggml-cpu-sandybridge.so
│       ├── libggml-cpu-skylakex.so
│       ├── libggml-cpu-sse42.so
│       ├── libggml-cpu-x64.so
│       └── cuda_v12
│           ├── libcublas.so.12
│           ├── libcublasLt.so.12
│           ├── libcudart.so.12
│           └── libggml-cuda.so
└── ... (66 files total)
```
Extract bin/ and lib/ directories separately or together.

### psql (postgres client) — linux/amd64 tar.gz
```
.
├── psql-17.2-linux-x86_64
│   ├── bin
│   │   └── psql
│   ├── lib
│   │   ├── libpq.so.5
│   │   ├── libz.so.1
│   │   ├── libzstd.so.1
│   │   ├── libssl.so.3
│   │   └── libcrypto.so.3
│   └── include
└── ... (75 files total)
```
Move the entire `psql-{ver}-{triplet}/` directory: `mv ./psql-*/ "$pkg_src_dir"`


## completionist examples

### gh 2.67.0 — linux/amd64 tar.gz
```
.
├── gh_2.67.0_linux_amd64
│   ├── bin
│   │   └── gh
│   ├── share
│   │   └── man
│   │       └── man1
│   │           ├── gh-actions-cache-delete.1
│   │           └── gh-actions-cache-list.1
│   └── LICENSE
└── ... (129 man pages)
```
Move the entire `gh_*/` directory: `mv ./gh_*/ "$pkg_src_dir"`


## pseudos examples

### yq — linux/amd64 tar.gz (WEBI_SINGLE=true)
```
.
├── yq_linux_amd64
└── yq.1
```
Binary is `yq_linux_amd64` — must rename to `yq` during install.

### pathman 0.6.0 — linux/amd64 tar.gz (WEBI_SINGLE=true)
```
.
└── pathman-v0.6.0-linux-amd64_v1
```
Binary name includes the full release tag. Rename to `pathman`.


## legion examples

### node 24.14.0 — linux/amd64 tar.xz
```
.
├── node-v24.14.0-linux-x64
│   ├── bin
│   │   ├── node
│   │   ├── npm -> ../lib/node_modules/npm/bin/npm-cli.js
│   │   └── npx -> ../lib/node_modules/npm/bin/npx-cli.js
│   ├── include
│   ├── lib
│   │   └── node_modules
│   └── share
└── ... (thousands of files)
```
Move entire directory: `mv ./node-*/ "$pkg_src_dir"`

### go 1.24.1 — linux/amd64 tar.gz
```
.
├── go
│   ├── bin
│   │   ├── go
│   │   └── gofmt
│   ├── src
│   └── pkg
└── ... (thousands of files)
```
Note: go's archive root directory is literally `go/` with no version in the name.


## pwsh example (heretic)

### pwsh 7.4.6 — linux/amd64 tar.gz
```
.
├── pwsh
├── Accessibility.dll
├── clrcompression.dll
├── clrjit.dll
├── createdump
├── cs
│   └── System.Private.CoreLib.resources.dll
├── de
│   └── System.Private.CoreLib.resources.dll
└── ... (727 files, all in same flat directory)
```
No subdirectory. Move all files into `$pkg_src_bin/`.


## Inspecting archives yourself

```sh
# tar.gz / tar.xz / tar.zst — list contents only (no extraction)
curl -fsSL "$URL" | tar -tz | head -20

# zip
curl -fsSL "$URL" -o /tmp/pkg.zip
unzip -l /tmp/pkg.zip | head -20

# For a .zst file when tar doesn't support zstd natively:
curl -fsSL "$URL" -o /tmp/pkg.tar.zst && zstd -dc /tmp/pkg.tar.zst | tar -tz | head -20
```

**What to look for**:
1. Is this one bare or compressed binary with no archive of files? (waif)
2. Is there a top-level directory? (prestige/heretic/caravan/completionist/legion) or no directory? (idealist/pseudos)
3. What is the directory named? Does it contain version? triplet?
4. Are there `completions/`, `autocomplete/`, `complete/` subdirs? (heretic)
5. Are there `.so`/`.dylib`/`.dll` files? (caravan or heretic)
6. Does the binary name match the command you want on PATH? (pseudos if not)
7. Is there a `bin/` directory at the top level? (completionist or legion)
