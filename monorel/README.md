---
title: monorel
homepage: https://github.com/therootcompany/golib/tree/main/tools/monorel
tagline: |
  monorel: Monorepo Release Tool for Go binaries.
---

To update or switch versions, run `webi monorel@stable` (or `@v0.6`, `@beta`,
etc).

### Files

These are the files that are created and/or modified with this installer:

```text
~/.config/envman/PATH.env
~/.local/bin/monorel
~/.local/opt/monorel-VERSION/bin/monorel
```

These are the files that monorel creates and/or modifies in your project:

```text
<module>/.goreleaser.yaml
.git/refs/tags/<module>/v*
```

## Cheat Sheet

> `monorel` manages independently-versioned Go modules and releases in a single
> repository — initializing goreleaser configs, bumping versions, and publishing
> multi-arch releases.

### How to use monorel

```sh
# Generate .goreleaser.yaml for all modules
monorel init --recursive ./

# Tag the next patch version for all modules with new commits
monorel bump --recursive ./

# Build, package, and publish GitHub releases for all binaries of a module
monorel release --recursive ./tools/monorel
```

### How monorepo versioning works

Each `go.mod` is an independently-versioned module. Tags use the module's path
as a prefix, and each module with binaries gets a `.goreleaser.yaml`:

```text
./
├── go.mod                          # v0.1.1 (library-only)
├── io/
│   └── transform/
│       └── gsheet2csv/
│           ├── go.mod              # io/transform/gsheet2csv/v1.0.5
│           ├── .goreleaser.yaml
│           └── cmd/
│               ├── gsheet2csv/
│               ├── gsheet2env/
│               └── gsheet2tsv/
└── tools/
    └── monorel/
        ├── go.mod                  # tools/monorel/v1.0.0
        └── .goreleaser.yaml
```

### `monorel init` vs `goreleaser init`

`goreleaser init` generates a config that assumes one module per repo and
derives names and versions from the git tag. That breaks in a monorepo with
prefixed tags. `monorel init` fixes this:

|               | `goreleaser init`           | `monorel init`                          |
| ------------- | --------------------------- | --------------------------------------- |
| Project name  | `{{ .ProjectName }}`        | Hard-coded binary name                  |
| Version       | Derived from git tag        | `{{ .Env.VERSION }}` (plain semver)     |
| Publishing    | goreleaser's built-in       | Disabled; uses `gh release` instead     |
| Multiple bins | Manual config               | Auto-discovered, shared via YAML anchor |
| Monorepo tags | (requires Pro subscription) | Prefix-aware (`cmd/foo/v1.2.3`)         |

### Generated `.goreleaser.yaml`: single binary

For a module with one binary (like `tools/monorel/`), the generated config has a
single build entry:

```yaml
builds:
  - id: monorel
    binary: monorel
    env:
      - CGO_ENABLED=0
    ldflags:
      - >-
        -s -w -X main.version={{.Env.VERSION}} -X main.commit={{.Commit}} -X
        main.date={{.Date}}
    goos:
      - darwin
      - linux
      - windows
      # ... and more

archives:
  - id: monorel
    ids: [monorel]
    # Hard-coded name instead of {{ .ProjectName }} — goreleaser derives
    # ProjectName from the prefixed tag, which would produce messy filenames.
    # {{ .Env.VERSION }} for the same reason — the raw tag version includes
    # the module path prefix.
    name_template: >-
      monorel_{{ .Env.VERSION }}_{{ title .Os }}_{{ .Arch }}

# goreleaser Pro would be needed to publish from a prefixed tag,
# so monorel disables goreleaser's publisher and uses 'gh release' instead.
release:
  disable: true
```

### Generated `.goreleaser.yaml`: multiple binaries

When a module has several commands under `cmd/`, monorel generates a build entry
per binary with shared settings via a YAML anchor:

```yaml
builds:
  - id: gsheet2csv
    binary: gsheet2csv
    main: ./cmd/gsheet2csv
    <<: &build_defaults
      env:
        - CGO_ENABLED=0
      ldflags:
        - >-
          -s -w -X main.version={{.Env.VERSION}}
      goos:
        - darwin
        - linux
        - windows
        # ...
  - id: gsheet2env
    binary: gsheet2env
    main: ./cmd/gsheet2env
    <<: *build_defaults
  - id: gsheet2tsv
    binary: gsheet2tsv
    main: ./cmd/gsheet2tsv
    <<: *build_defaults

archives:
  - id: gsheet2csv
    # All binaries are bundled into one archive per platform.
    ids: [gsheet2csv, gsheet2env, gsheet2tsv]
    # Same hard-coded name and {{ .Env.VERSION }} to avoid prefixed tag leaking.
    name_template: >-
      gsheet2csv_{{ .Env.VERSION }}_{{ title .Os }}_{{ .Arch }}

# Same as single binary — disable goreleaser's publisher for monorepo tags.
release:
  disable: true
```

All three binaries share one version tag (`io/transform/gsheet2csv/v1.0.5`) and
one GitHub release.
