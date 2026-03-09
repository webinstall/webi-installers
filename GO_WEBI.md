# Go Webi — Rewrite Plan

This is the planning and tracking document for rewriting the Webi server in Go.
This is **not a straight port** — we're redesigning internals while preserving the
public API surface.

## Guiding Principles

1. **Incremental migration.** Rewrites fail when they try to replace everything
   at once. We integrate piece by piece, endpoint by endpoint, into the live
   system.
2. **Library over framework.** The Go code should be composable pieces the caller
   controls — not a framework that calls your code.
3. **stdlib + pgx, nothing else.** No third-party SDKs. Dependencies: stdlib,
   `golang.org/x`, `github.com/jackc/pgx`, `github.com/therootcompany/golib`.
4. **Resilient by default.** The HTTP client, caching, and storage layers are
   built for failure — timeouts, retries, circuit breaking, graceful fallback.
5. **Simpler classification.** Standard toolchains (goreleaser, cargo-dist, etc.)
   produce predictable filenames. Match those patterns directly; push esoteric
   naming into release-fetcher tagging/filtering rather than classifier heuristics.

## Repository Layout

```
cmd/
  webid/              # main HTTP server
  webicached/         # release cache daemon (fetches + stores releases)
internal/
  buildmeta/          # OS, arch, libc, format constants and enums
  classify/           # build artifact classification (filename → target)
  httpclient/         # resilient net/http client with best-practice defaults
  lexver/             # lexicographic version parsing and sorting
  releases/           # release fetching (GitHub, Gitea, git-tag, custom)
    github/
    gitea/
    gittag/
  render/             # installer script template rendering
  storage/            # release storage interface + implementations
    storage.go        # interface definition
    fsstore/          # filesystem (JSON cache, like current _cache/)
    pgstore/          # PostgreSQL (via sqlc + pgx)
  uadetect/           # User-Agent → OS/arch/libc detection
```

## Public API Surface (Must Remain Stable)

These are the endpoints that clients depend on. The URLs, query parameters, and
response formats must not change.

### Bootstrap (curl-pipe entry point)

```
GET /{package}            # User-Agent dispatch:
GET /{package}@{version}  #   curl/wget/POSIX → bash bootstrap script
                          #   PowerShell      → ps1 bootstrap script
                          #   Browser         → HTML cheat sheet (separate app)
```

### Installer Scripts

```
GET /api/installers/{package}.sh                # POSIX installer
GET /api/installers/{package}@{version}.sh
GET /api/installers/{package}.ps1               # PowerShell installer
GET /api/installers/{package}@{version}.ps1

Query: ?formats=tar,zip,xz,git,dmg,pkg
       &libc=msvc  (ps1 only)
```

### Release Metadata

```
GET /api/releases/{package}.json
GET /api/releases/{package}@{version}.json
GET /api/releases/{package}.tab
GET /api/releases/{package}@{version}.tab

Query: ?os=linux&arch=amd64&libc=musl
       &channel=stable&limit=10&formats=tar,xz
       &pretty=true
```

### Package Assets

```
GET /packages/{package}/README.md
GET /packages/{package}/{filename}
```

### Debug

```
GET /api/debug            # returns detected OS/arch from User-Agent
Query: ?os=...&arch=...   # overrides
```

### Response Formats

**JSON** — `{ oses, arches, libcs, formats, releases: [{ version, date, os,
arch, libc, ext, download, channel, lts, name }] }`

**TSV (.tab)** — `version \t lts \t channel \t date \t os \t arch \t ext \t - \t
download \t name \t comment`

## Architecture

### Two Servers

- **`webid`** — the HTTP API server. Renders templates and serves responses.
  On each request, looks up releases by package name in storage (filesystem
  and/or Postgres, configurable). No package registry — if releases exist in
  storage for that name, it's a valid package. No restart needed when packages
  are added.
- **`webicached`** — the cache daemon. Built with its package set compiled in.
  Periodically fetches releases from upstream sources, classifies builds, and
  writes to both Postgres and the filesystem. Adding a new package means
  rebuilding and redeploying `webicached`.

**Adding a new installer requires rebuilding `webicached`, but not `webid`.** The
API server discovers packages from storage — when the new `webicached` writes a
package's releases to Postgres or the filesystem, `webid` sees it on the next
read. No restart, no config reload.

This means `webid` never blocks on upstream API calls. It serves from whatever is
in storage — always fast, always available.

### Double-Buffer Storage

The storage layer uses a double-buffer strategy so that a full release-history
rewrite never disrupts active downloads:

```
Slot A: [current — being read by webid]
Slot B: [next — being written by webicached]

On completion: atomic swap A ↔ B
```

For **fsstore**: two directories per package, swap via atomic rename.
For **pgstore**: two sets of rows per package (keyed by generation), swap via
updating an active-generation pointer in a single transaction.

### Storage Interface

```go
type Store interface {
    // Read path (used by webid)
    GetPackageMeta(ctx context.Context, name string) (*PackageMeta, error)
    GetReleases(ctx context.Context, name string, filter ReleaseFilter) ([]Release, error)

    // Write path (used by webicached)
    BeginRefresh(ctx context.Context, name string) (RefreshTx, error)
}

type RefreshTx interface {
    PutReleases(ctx context.Context, releases []Release) error
    Commit(ctx context.Context) error   // atomic swap
    Rollback(ctx context.Context) error
}
```

### Resilient HTTP Client (`internal/httpclient`)

A `net/http` client with best-practice defaults, used as the base for all
upstream API calls:

- **Timeouts**: connect, TLS handshake, response header, overall request
- **Connection pooling**: sensible `MaxIdleConns`, `IdleConnTimeout`
- **TLS**: `MinVersion: tls.VersionTLS12`, system cert pool
- **Redirects**: limited redirect depth, no cross-scheme downgrades
- **User-Agent**: identifies as Webi with contact info
- **Retries**: exponential backoff with jitter for transient errors (429, 502,
  503, 504), respects `Retry-After` headers
- **Context**: all calls take `context.Context` for cancellation
- **No global state**: created as instances, not `http.DefaultClient`

### Release Fetchers (`internal/releases/`)

Each upstream source (GitHub, Gitea, git-tag) is a small package that uses
`httpclient` and returns a common `[]Release` slice. No SDK dependencies.

```go
// internal/releases/github/github.go
func FetchReleases(ctx context.Context, client *httpclient.Client,
    owner, repo string, opts ...Option) ([]Release, error)
```

### Build Classification (`internal/classify`)

Simplified from the current regex-heavy approach. Strategy:

1. **Known toolchain patterns first.** Goreleaser, cargo-dist, and Go's release
   naming are predictable. Match those structures directly.
2. **Fallback regex for legacy.** Keep a simpler set of OS/arch/libc/ext regexes
   for packages that don't use standard toolchains.
3. **Release-fetcher does the hard work.** The `releases.js` (or its Go
   equivalent config) is responsible for filtering irrelevant assets and
   normalizing oddball names _before_ classification sees them.

Target triplet format: `{os}-{arch}-{libc}` (simplified from the current
4-part `{arch}-{vendor}-{os}-{libc}`).

### Installer Rendering (`internal/render`)

Replaces `installers.js`. Reads template files, substitutes variables, injects
the per-package `install.sh` / `install.ps1`.

The current template variable set (30+ env vars) is the contract with the
client-side scripts. We must produce identical output for `package-install.tpl.sh`
and `package-install.tpl.ps1`.

### Reworking install.sh / install.ps1

Long-term, the per-package install scripts should feel like library users, not
framework callbacks:

- **Current (framework):** define `pkg_install()`, `pkg_get_current_version()`,
  etc. and the framework calls them.
- **Goal (library):** source a helpers file, call functions like
  `webi_download`, `webi_extract`, `webi_link` explicitly from a linear script.

This is a **separate migration** from the Go rewrite — it changes the client-side
contract. Plan it but don't block the server rewrite on it.

## Migration Strategy

Each phase produces something that works in production alongside the existing
Node.js server.

### Phase 0: Foundation

- [ ] `internal/buildmeta` — constants/enums for OS, arch, libc, format, channel
- [ ] `internal/lexver` — version parsing and comparison
- [ ] `internal/httpclient` — resilient HTTP client
- [ ] `internal/uadetect` — User-Agent parsing
- [ ] Go module init, CI setup

### Phase 1: Release Fetching

- [ ] `internal/releases/github` — GitHub releases fetcher
- [ ] `internal/releases/gitea` — Gitea releases fetcher
- [ ] `internal/releases/gittag` — git tag listing
- [ ] `internal/classify` — build artifact classifier
- [ ] `internal/storage` — interface definition
- [ ] `internal/storage/fsstore` — filesystem implementation with double-buffer
- [ ] `cmd/webicached` — cache daemon that can replace the Node.js caching

**Integration point:** `webicached` writes the same `_cache/` JSON format. The
Node.js server can read from it. Zero-risk cutover for release fetching.

### Phase 2: Release API

- [ ] `cmd/webid` — HTTP server skeleton with middleware
- [ ] `GET /api/releases/{package}.json` endpoint
- [ ] `GET /api/releases/{package}.tab` endpoint
- [ ] `GET /api/debug` endpoint

**Integration point:** reverse proxy specific `/api/releases/` paths to the Go
server. Node.js handles everything else.

### Phase 3: Installer Rendering

- [ ] `internal/render` — template engine
- [ ] `GET /api/installers/{package}.sh` endpoint
- [ ] `GET /api/installers/{package}.ps1` endpoint
- [ ] Bootstrap endpoint (`GET /{package}`)

**Integration point:** reverse proxy installer paths to Go. Node.js only serves
the website/cheat sheets (if it ever did — that may be a separate app).

### Phase 4: PostgreSQL Storage

- [ ] `internal/storage/pgstore` — sqlc-generated queries, double-buffer
- [ ] Schema design and migrations
- [ ] `webicached` writes to Postgres
- [ ] `webid` reads from Postgres

### Phase 5: Client-Side Rework

- [ ] Design new library-style install.sh helpers
- [ ] Migrate existing packages one at a time
- [ ] Update `package-install.tpl.sh` to support both old and new styles

## Key Design Decisions

### Version: Go 1.26+

Using `http.ServeMux` with `PathValue` for routing (available since Go 1.22).
Middleware via `github.com/therootcompany/golib/http/middleware/v2`.

### No ORM

PostgreSQL access via `pgx` + `sqlc`. Queries are hand-written SQL, type-safe
Go code is generated.

### Template Rendering

Use `text/template` or simple string replacement (matching current behavior).
The templates are shell scripts — they need literal `$` and `{}` — so
`text/template` may be the wrong tool. Likely better to stick with the current
regex-replacement approach, ported to Go.

### Error Handling

The current system returns a synthetic "error release" (`version: 0.0.0`,
`channel: error`) when no match is found, rather than an HTTP error. This
behavior must be preserved for backward compatibility.

## Open Questions

- [ ] Should `webicached` shell out to `node releases.js` during migration, or
  do we rewrite every releases.js as Go config/code from the start? (Shelling
  out preserves hot-add compatibility during the transition — a new `releases.js`
  just works without any Go changes.)
- [ ] What's the deployment topology? Single binary serving both roles? Separate
  processes? Kubernetes pods?
- [ ] Rate limiting for GitHub API calls in `webicached` — how to coordinate
  across multiple instances?

## Current Node.js Architecture (Reference)

For context, the current system's key files:

| File | Role |
|------|------|
| `_webi/serve-installer.js` | Main request handler — dispatches to builds + rendering |
| `_webi/builds.js` | Thin wrapper around builds-cacher |
| `_webi/builds-cacher.js` | Release fetching, caching, classification, version matching |
| `_webi/transform-releases.js` | Legacy release API (filter + cache + serve) |
| `_webi/normalize.js` | OS/arch/libc/ext regex detection from filenames |
| `_webi/installers.js` | Template rendering (bash + powershell) |
| `_webi/ua-detect.js` | User-Agent → OS/arch/libc |
| `_webi/projects.js` | Package metadata from README frontmatter |
| `_webi/frontmarker.js` | YAML frontmatter parser |
| `_common/github.js` | GitHub releases fetcher |
| `_common/gitea.js` | Gitea releases fetcher |
| `_common/git-tag.js` | Git tag listing |
| `{pkg}/releases.js` | Per-package release config (fetcher + filters + transforms) |
| `{pkg}/install.sh` | Per-package POSIX installer |
| `{pkg}/install.ps1` | Per-package PowerShell installer |
