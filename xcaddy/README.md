---
title: Custom Caddy Builder
homepage: https://github.com/caddyserver/xcaddy
tagline: |
  xcaddy makes it easy to make custom builds of the Caddy Web Server
---

To update or switch versions, run `webi xcaddy@stable` (or `@v0.3`, `@beta`,
etc).

### Files

These are the files / directories that are created and/or modified with this
install:

```text
~/.config/envman/PATH.env
~/.local/bin/xcaddy
~/.local/opt/go/
~/go/bin/
```

## Cheat Sheet

> `xcaddy` makes it easy to build caddy with DNS providers, and to test builds
> of feature branches and PRs.

Build with `xcaddy`:

```sh
CGO_ENABLED=0 xcaddy build 'v2.7.5' \
    --with github.com/caddy-dns/duckdns \
    --with github.com/caddy-dns/lego-deprecated \
    --output ./caddy-v2.7.5-extras
```

See that it worked:

```sh
./caddy-v2.7.5-extras list-modules
# v2.7.5 h1:HoysvZkLcN2xJExEepaFHK92Qgs7xAiCFydN5x5Hs6Q=
```

Other helpful tips:

- Caddy Versions
- DNS Providers
- Other Modules
- Cross-Compiling
- Build a Feature Branch
- Build a Fork
- List Built-In Modules
- Common ENVs

### How to List Available Caddy Versions

<https://github.com/caddyserver/caddy/releases>

See also:

- <https://github.com/caddyserver/caddy/tags>
- <https://webinstall.dev/api/releases/caddy.json?pretty=true&channel=stable&os=linux&arch=amd64&limit=10>
- <https://webinstall.dev/api/releases/caddy.tab?channel=stable&os=linux&arch=amd64&limit=100>

### How to Find DNS Providers

There are two types of DNS Providers:

**1.`libdns`**

These providers each have their own module, most of which can be searched here:

- <https://github.com/caddy-dns>
- <https://caddyserver.com/docs/modules/> (search `dns.providers`)

**2. `lego` (legacy)**

This module bundles _many_ providers together, _all_ of which are listed here:

- `github.com/caddy-dns/lego-deprecated`
- <https://github.com/go-acme/lego#dns-providers>
- <https://caddyserver.com/docs/modules/dns.providers.lego_deprecated>

### How to Find Other Modules

There are a variety of other modules, including things like `ngrok`, `s3`,
`layer4`, and others.

Most module authors register them in the caddy modules docs:

- <https://caddyserver.com/docs/modules/>

However, a module can be loaded from any Git URL (not just GitHub).

Note: Modules are named internally by their namespace (e.g. `dns.providers.x`),
but referenced externally by their Git URL .

### How to Cross-Compile

Use `CGO_ENABLED`, `GOOS`, `GOARCH`, and `GOARM` (for 32-bit ARM):

```sh
GOOS=linux GOARCH=arm64 GOARM= \
CGO_ENABLED=0 \
    xcaddy build 'v2.7.5' \
    --with github.com/caddy-dns/duckdns \
    --with github.com/caddy-dns/lego-deprecated \
    --output ./caddy-v2.7.5-extras
```

You can _inline_ (as seen above) or `export` the ENVs:

```sh
export GOOS=linux
export GOARCH=arm64
export GOARM=
export CGO_ENABLED=0

xcaddy build 'v2.7.5' \
    --with github.com/caddy-dns/duckdns \
    --with github.com/caddy-dns/lego-deprecated \
    --output ./caddy-v2.7.5-extras
```

Using `CGO_ENABLED=0` can only build pure Go programs, which means that
cross-compiling is guaranteed to succeed (assuming the modules don't contain C),
however, file sizes may be slightly larger for bundling Go modules for DNS
resolution, etc, which your OS would otherwise provide.

Common OSes and Arches are:

- `linux`, `darwin`, `windows`, `freebsd`
- `amd64`, `arm64`, `mips`, `ppc64le`

See also:

- OSes: `go tool dist list | cut -d/ -f1 | sort -u`
- Arches: `go tool dist list | cut -d/ -f2 | sort -u`

### How to Build From a Feature Branch

The `build` is actually a [commit-ish][commit-ish] (a.k.a. a "git ref"), which
can apply to any branch of the official repository:

```sh
xcaddy build "file-placeholder"
```

See also:

- <https://github.com/caddyserver/caddy/tags>
- <https://github.com/caddyserver/caddy/branches>
- <https://github.com/caddyserver/caddy/commits/master>

[commit-ish]:
  https://mirrors.edge.kernel.org/pub/software/scm/git/docs/#_identifier_terminology

### How to List Built-In Modules

When it's time to rebuild `caddy` and you've forgotten which modules you used to
build it, fear not!

`list-modules` to the rescue!

```sh
caddy list-modules
```

```text
admin.api.load
# ... 104 other modules
tls.stek.standard

  Standard modules: 106

dns.providers.duckdns

  Non-standard modules: 1
```

### Common Options

Here are some of the common environment variables that change xcaddy's behavior:

| Option                 | Description                                                   |
| ---------------------- | ------------------------------------------------------------- |
| `CGO_ENABLED`          | Set to `0` to build pure Go (no C or OS libraries)            |
| `GOOS`                 | For cross-compiling: `linux`, `darwin`, `windows`, etc        |
| `GOARCH`               | For cross-compiling: `amd64`, `arm64`, `arm`, etc             |
| `GOARM`                | For cross-compiling arm (32-bit): `7` or `6` (8 is arm64)     |
| `CADDY_VERSION`        | Equivalent to `xcaddy build "$CADDY_VERSION" ...`             |
| `XCADDY_SETCAP=1`      | Linux: runs [`sudo setcap cap_net_bind_service=+ep`][netbind] |
| `XCADDY_SUDO=0`        | Don't use `sudo` for `XCADDY_SETCAP` (i.e. on Alpine)         |
| `XCADDY_RACE_DETECTOR` | For finding race conditions in feature builds                 |
| `XCADDY_DEBUG=1`       | Disables `-ldflags '-w -s'`, for debug builds                 |
| `XCADDY_SKIP_CLEANUP`  | Leaves build files (for debugging failure)                    |
| `XCADDY_SKIP_BUILD`    | For use with building & releasing custom builds w/ GoReleaser |

[netbind]: ../setcap-netbind/

See also:

- `go tool dist list`
- <https://github.com/caddyserver/xcaddy#environment-variables>
