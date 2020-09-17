---
title: Caddy
homepage: https://github.com/caddyserver/caddy
tagline: |
  Caddy is a fast, multi-platform web server with automatic HTTPS.
---

## Updating `caddy`

```bash
webi caddy@stable
```

Use the `@beta` tag for pre-releases, or `@x.y.z` for a specific version.

## Cheat Sheet

> Caddy makes it easy to use Let's Encrypt to handle HTTPS (TLS/SSL) and to
> reverse proxy APIs and WebSockets to other apps - such as those written node,
> Go, python, ruby, and PHP.

### How to serve a directory

```bash
caddy file-server --browse --listen :4040
```

### How to redirect and reverse proxy

Here's what a fairly basic `Caddyfile` looks like:

```txt
# redirect www to bare domain
www.example.com {
    redir https://example.com{uri} permanent
}

example.com {
    # log to stdout, which is captured by journalctl
    log {
        output stdout
        format console
    }

    # turn on standard streaming compression
    encode gzip zstd

    # reverse proxy /api to :3000
    reverse_proxy /api/* localhost:3000

    # serve static files from public folder, but not /api
    @notApi {
        file {
            try_files {path} {path}/ {path}/index.html
        }
        not path /api/*
    }
    route {
      rewrite @notApi {http.matchers.file.relative}
    }
    root * /srv/example.com/public/
    file_server
}
```

And here's how you run caddy with it:

```bash
caddy run --config ./Caddyfile
```
