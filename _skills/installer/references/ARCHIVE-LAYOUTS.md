# Archive Layouts — Real Package Examples

Actual `tar -t` / `unzip -l` output for representative packages.
Use these to calibrate your eye for what each pattern looks like.

---

## Pattern A — Flat archive (no subdirectory)

### caddy 2.9.1 — linux/amd64 tar.gz
```
caddy
LICENSE
README.md
```
Binary `caddy` is at the top level. Set `WEBI_SINGLE=true`.

### fzf 0.70.0 — linux/amd64 tar.gz
```
fzf
```
Minimal — just the binary.

### terraform 1.9.8 — linux/amd64 zip
```
terraform
LICENSE.txt
```
Zip archive but same flat layout.

### k9s — linux/amd64 tar.gz
```
k9s
LICENSE
README.md
```

---

## Pattern B — Named subdirectory, binary only

### delta 0.18.2 — linux/amd64 tar.gz
```
delta-0.18.2-x86_64-unknown-linux-musl/
delta-0.18.2-x86_64-unknown-linux-musl/delta
delta-0.18.2-x86_64-unknown-linux-musl/LICENSE
delta-0.18.2-x86_64-unknown-linux-musl/README.md
```
Glob to move: `./delta-*/delta`

### shellcheck 0.10.0 — linux/x86_64 tar.xz
```
shellcheck-v0.10.0/
shellcheck-v0.10.0/shellcheck
shellcheck-v0.10.0/LICENSE.txt
shellcheck-v0.10.0/README.txt
```
Glob to move: `./shellcheck-*/shellcheck`

### xsv 0.13.0 — linux/x86_64 tar.gz
```
xsv-0.13.0-x86_64-unknown-linux-musl/
xsv-0.13.0-x86_64-unknown-linux-musl/xsv
xsv-0.13.0-x86_64-unknown-linux-musl/UNLICENSE
```

---

## Pattern C — Subdirectory + completions + man pages

### rg/ripgrep 14.1.1 — linux/amd64 tar.gz
```
ripgrep-14.1.1-x86_64-unknown-linux-musl/
ripgrep-14.1.1-x86_64-unknown-linux-musl/rg
ripgrep-14.1.1-x86_64-unknown-linux-musl/complete/
ripgrep-14.1.1-x86_64-unknown-linux-musl/complete/_rg
ripgrep-14.1.1-x86_64-unknown-linux-musl/complete/_rg.ps1
ripgrep-14.1.1-x86_64-unknown-linux-musl/complete/rg.bash
ripgrep-14.1.1-x86_64-unknown-linux-musl/complete/rg.fish
ripgrep-14.1.1-x86_64-unknown-linux-musl/doc/
ripgrep-14.1.1-x86_64-unknown-linux-musl/doc/rg.1
ripgrep-14.1.1-x86_64-unknown-linux-musl/doc/FAQ.md
ripgrep-14.1.1-x86_64-unknown-linux-musl/doc/GUIDE.md
ripgrep-14.1.1-x86_64-unknown-linux-musl/CHANGELOG.md
ripgrep-14.1.1-x86_64-unknown-linux-musl/LICENSE-MIT
ripgrep-14.1.1-x86_64-unknown-linux-musl/README.md
```
Note: completions are in `complete/` (not `completions/`). Man page is `doc/rg.1`.

### sd 1.1.0 — linux/x86_64 tar.gz
```
sd-v1.1.0-x86_64-unknown-linux-musl/
sd-v1.1.0-x86_64-unknown-linux-musl/sd
sd-v1.1.0-x86_64-unknown-linux-musl/sd.1
sd-v1.1.0-x86_64-unknown-linux-musl/completions/
sd-v1.1.0-x86_64-unknown-linux-musl/completions/sd.bash
sd-v1.1.0-x86_64-unknown-linux-musl/completions/sd.elv
sd-v1.1.0-x86_64-unknown-linux-musl/completions/sd.fish
sd-v1.1.0-x86_64-unknown-linux-musl/completions/_sd
sd-v1.1.0-x86_64-unknown-linux-musl/completions/_sd.ps1
sd-v1.1.0-x86_64-unknown-linux-musl/CHANGELOG.md
sd-v1.1.0-x86_64-unknown-linux-musl/LICENSE
sd-v1.1.0-x86_64-unknown-linux-musl/README.md
```
Note: man page `sd.1` is at subdirectory root. Completions in `completions/`.

### bat 0.26.1 — linux/amd64 tar.gz
```
bat-v0.26.1-x86_64-unknown-linux-musl/
bat-v0.26.1-x86_64-unknown-linux-musl/bat
bat-v0.26.1-x86_64-unknown-linux-musl/bat.1
bat-v0.26.1-x86_64-unknown-linux-musl/autocomplete/
bat-v0.26.1-x86_64-unknown-linux-musl/autocomplete/bat.bash
bat-v0.26.1-x86_64-unknown-linux-musl/autocomplete/bat.fish
bat-v0.26.1-x86_64-unknown-linux-musl/autocomplete/bat.zsh
bat-v0.26.1-x86_64-unknown-linux-musl/LICENSE-APACHE
bat-v0.26.1-x86_64-unknown-linux-musl/LICENSE-MIT
bat-v0.26.1-x86_64-unknown-linux-musl/README.md
```
Note: completions in `autocomplete/` (not `completions/`). Zsh file is `bat.zsh` not `_bat`.

### goreleaser — linux/amd64 tar.gz
```
goreleaser
completions/
completions/goreleaser.bash
completions/goreleaser.fish
completions/goreleaser.zsh
manpages/
manpages/goreleaser.1.gz
LICENSE.md
README.md
```
Note: goreleaser uses Pattern A layout (binary at root, no subdirectory)
but includes completions and a gzipped man page. Set `WEBI_SINGLE=true`;
move completions and man page after the binary.

---

## Pattern D — Binary + shared libraries

### ollama 0.17.7 — linux/amd64 tar.zst
```
bin/
bin/ollama
lib/
lib/ollama/
lib/ollama/libggml-base.so
lib/ollama/libggml-cpu-alderlake.so
lib/ollama/libggml-cpu-haswell.so
lib/ollama/libggml-cpu-icelake.so
lib/ollama/libggml-cpu-sandybridge.so
lib/ollama/libggml-cpu-skylakex.so
lib/ollama/libggml-cpu-sse42.so
lib/ollama/libggml-cpu-x64.so
lib/ollama/cuda_v12/
lib/ollama/cuda_v12/libcublas.so.12
lib/ollama/cuda_v12/libcublasLt.so.12
lib/ollama/cuda_v12/libcudart.so.12
lib/ollama/cuda_v12/libggml-cuda.so
... (66 files total)
```
Extract bin/ and lib/ directories separately or together.

### psql (postgres client) — linux/amd64 tar.gz
```
psql-17.2-linux-x86_64/
psql-17.2-linux-x86_64/bin/
psql-17.2-linux-x86_64/bin/psql
psql-17.2-linux-x86_64/lib/
psql-17.2-linux-x86_64/lib/libpq.so.5
psql-17.2-linux-x86_64/lib/libz.so.1
psql-17.2-linux-x86_64/lib/libzstd.so.1
psql-17.2-linux-x86_64/lib/libssl.so.3
psql-17.2-linux-x86_64/lib/libcrypto.so.3
psql-17.2-linux-x86_64/include/
... (75 files total)
```
Move the entire `psql-{ver}-{triplet}/` directory: `mv ./psql-*/ "$pkg_src_dir"`

---

## Pattern E — FHS layout

### gh 2.67.0 — linux/amd64 tar.gz
```
gh_2.67.0_linux_amd64/
gh_2.67.0_linux_amd64/bin/
gh_2.67.0_linux_amd64/bin/gh
gh_2.67.0_linux_amd64/share/
gh_2.67.0_linux_amd64/share/man/
gh_2.67.0_linux_amd64/share/man/man1/
gh_2.67.0_linux_amd64/share/man/man1/gh-actions-cache-delete.1
gh_2.67.0_linux_amd64/share/man/man1/gh-actions-cache-list.1
... (129 man pages)
gh_2.67.0_linux_amd64/LICENSE
```
Move the entire `gh_*/` directory: `mv ./gh_*/ "$pkg_src_dir"`

---

## Pattern F — Binary needs rename

### yq — linux/amd64 tar.gz (WEBI_SINGLE=true)
```
yq_linux_amd64
yq.1
```
Binary is `yq_linux_amd64` — must rename to `yq` during install.

### pathman 0.6.0 — linux/amd64 tar.gz (WEBI_SINGLE=true)
```
pathman-v0.6.0-linux-amd64_v1
```
Binary name includes the full release tag. Rename to `pathman`.

---

## Pattern G — Full SDK

### node 24.14.0 — linux/amd64 tar.xz
```
node-v24.14.0-linux-x64/
node-v24.14.0-linux-x64/bin/
node-v24.14.0-linux-x64/bin/node
node-v24.14.0-linux-x64/bin/npm     -> ../lib/node_modules/npm/bin/npm-cli.js
node-v24.14.0-linux-x64/bin/npx     -> ../lib/node_modules/npm/bin/npx-cli.js
node-v24.14.0-linux-x64/include/
node-v24.14.0-linux-x64/lib/
node-v24.14.0-linux-x64/lib/node_modules/
node-v24.14.0-linux-x64/share/
... (thousands of files)
```
Move entire directory: `mv ./node-*/ "$pkg_src_dir"`

### go 1.24.1 — linux/amd64 tar.gz
```
go/
go/bin/
go/bin/go
go/bin/gofmt
go/src/
go/pkg/
... (thousands of files)
```
Note: go's archive root directory is literally `go/` with no version in the name.

---

## Pattern H — .NET runtime bundle

### pwsh 7.4.6 — linux/amd64 tar.gz
```
pwsh
Accessibility.dll
clrcompression.dll
clrjit.dll
createdump
cs/
cs/System.Private.CoreLib.resources.dll
de/
de/System.Private.CoreLib.resources.dll
... (727 files, all in same flat directory)
```
No subdirectory. Move all files into `$pkg_src_bin/`.

---

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
1. Is there a top-level directory? (Pattern B/C/D/E/G) or no directory? (Pattern A/F/H)
2. What is the directory named? Does it contain version? triplet?
3. Are there `completions/`, `autocomplete/`, `complete/` subdirs? (Pattern C)
4. Are there `.so`/`.dylib`/`.dll` files? (Pattern D or H)
5. Does the binary name match the command you want on PATH? (Pattern F if not)
6. Is there a `bin/` directory at the top level? (Pattern E or G)
