# Install Patterns Reference

Nine patterns cover the full range of webi packages. Pattern A is by far
the most common. Check `tar -tz $ARCHIVE` before writing any code.

---

## Pattern A — Bare binary at archive root

The archive extracts directly to the current directory with no wrapper
subdirectory. Binary (and optional LICENSE/README) is at the top level.

**Set `WEBI_SINGLE=true`** — tells the framework the archive is flat.

Representative packages: caddy, fzf, k9s, terraform, sttr, lf, monorel,
awless, bun, cilium, curlie, dashmsg, dotenv, dotenv-linter, ffuf,
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

---

## Pattern B — Binary inside a version/triplet subdirectory

Archive extracts to a single directory named with the version and/or
platform triplet. Binary (and docs) live inside that directory.

Representative packages: delta, hexyl, shellcheck, trip, xsv, kubectx, kubens

**Subdirectory naming conventions seen in the wild**:
- `tool-{ver}-{triplet}/` — most Rust tools (delta, shellcheck, xsv)
- `tool-{ver}/` — simpler version-only dirs
- flat (no dir) — kubectx/kubens use flat archives despite being "B-ish"

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

---

## Pattern C — Subdirectory with binary + completions and/or man pages

Same as B but the archive also contains shell completions and/or man pages
worth installing.

Representative packages: bat, fd, goreleaser, lsd, rg/ripgrep, sd,
watchexec, zoxide

**Completion directory name varies by package**:
- `completions/` — sd, goreleaser, watchexec, zoxide
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
- `manpages/tool.1.gz` — goreleaser
- `man/man1/tool.1` — zoxide (deepest path)

**install.sh** (rg as example):
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
    if [ -e ./ripgrep-*/complete/rg.bash ]; then
        mkdir -p "$pkg_src_dir/share/bash-completion/completions"
        mv ./ripgrep-*/complete/rg.bash \
            "$pkg_src_dir/share/bash-completion/completions/rg"
    fi
    # fish completion
    if [ -e ./ripgrep-*/complete/rg.fish ]; then
        mkdir -p "$pkg_src_dir/share/fish/vendor_completions.d"
        mv ./ripgrep-*/complete/rg.fish \
            "$pkg_src_dir/share/fish/vendor_completions.d/rg.fish"
    fi
    # zsh completion
    if [ -e './ripgrep-*/complete/_rg' ]; then
        mkdir -p "$pkg_src_dir/share/zsh/site-functions"
        mv './ripgrep-*/complete/_rg' \
            "$pkg_src_dir/share/zsh/site-functions/_rg"
    fi
    # man page
    if [ -e ./ripgrep-*/doc/rg.1 ]; then
        mkdir -p "$pkg_src_dir/share/man/man1"
        mv ./ripgrep-*/doc/rg.1 "$pkg_src_dir/share/man/man1/rg.1"
    fi
}

pkg_get_current_version() {
    rg --version 2>/dev/null | head -n 1 | cut -d' ' -f2
}
```

**Note**: Completion paths in completions/man install are best-effort
— use `if [ -e ... ]` guards so the script still works on older releases
that didn't include them.

---

## Pattern D — Binary + shared libraries

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

---

## Pattern E — FHS-like layout

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
    mv ./gh_*/ "$pkg_src_dir"
}

pkg_get_current_version() {
    gh --version 2>/dev/null | head -n 1 | cut -d' ' -f3
}
```

No `chmod` needed — binary is already executable inside the archive.

---

## Pattern F — Binary needs rename

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

---

## Pattern G — Full SDK / toolchain

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

---

## Pattern H — .NET runtime bundle

Flat directory with one binary and hundreds of `.dll` files. The entire
directory must be preserved intact.

Representative packages: pwsh (PowerShell Core)

**install.sh**:
```sh
pkg_cmd_name="pwsh"

pkg_dst_cmd="$HOME/.local/bin/pwsh"
pkg_dst="$pkg_dst_cmd"
pkg_src_cmd="$HOME/.local/opt/pwsh-v$WEBI_VERSION/bin/pwsh"
pkg_src_dir="$HOME/.local/opt/pwsh-v$WEBI_VERSION"
pkg_src="$pkg_src_cmd"

pkg_install() {
    mkdir -p "$pkg_src_dir"
    # Archive extracts flat — move all contents into bin/
    mkdir -p "$pkg_src_bin"
    mv ./* "$pkg_src_bin/" 2>/dev/null || true
    chmod a+x "$pkg_src_cmd"
}
```

---

## Pattern I — Multi-binary distribution

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

---

## Choosing between patterns

```
Archive root contains a single binary (or binary + docs)?
  → Pattern A  (set WEBI_SINGLE=true)

Archive has a named subdirectory wrapping the binary?
  ├─ Binary only inside subdir?         → Pattern B
  ├─ Binary + completions/man pages?    → Pattern C
  └─ Binary + shared libraries (.so)?  → Pattern D

Archive already has bin/ and share/ layout?
  → Pattern E

Binary name doesn't match the command name?
  → Pattern F  (rename during install)

Archive is a full SDK (compiler, runtime, stdlib)?
  → Pattern G  (pkg_src = pkg_src_dir)

Flat directory with many DLLs (.NET)?
  → Pattern H

Multiple binaries for a single distributed system?
  → Pattern I
```
