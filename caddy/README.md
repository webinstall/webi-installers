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

Here's the things we find most useful:

- Simple File & Directory Server
- Reverse Proxy with www (and HTTPS) redirects
- Running as a system service on
  - Linux
  - MacOS
  - Windows 10

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

    # reverse proxy some "well known" APIs
    reverse_proxy /.well-known/openid-configuration localhost:3000
    reverse_proxy /.well-known/jwks.json localhost:3000

    # serve static files from public folder, but not /api
    @notApi {
        file {
            try_files {path} {path}/ {path}/index.html
        }
        not path /api/*
        not path /.well-known/openid-configuration
        not path /.well-known/jwks.json
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

### How to start Caddy as a Linux service

Here are the 3 things you need to do to start Caddy as a system service:

**a non-root user**

If you don't have a non-root user, consider adding the `app` user with
[`ssh-adduser`](https://webinstall.dev/ssh-adduser).

Using a user named `app` to run your services is common industry convention.

**port-binding privileges**

You can use `setcap` to allow Caddy to use privileged ports.

```bash
sudo setcap cap_net_bind_service=+ep $(readlink -f $(command -v caddy))
```

**systemd config**

You can use [`serviceman`](https://webinstall.dev/serviceman) to create and
start the appropriate systemd launcher for Linux.

Install Serviceman with Webi:

```bash
webi serviceman
```

Use Serviceman to create a _systemd_ config file.

```bash
sudo env PATH="$PATH" \
    serviceman add --system --username $(whoami) --name caddy -- \
        caddy run --config ./Caddyfile
```

This will create `/etc/systemd/system/caddy.service`, which can be managed with
`systemctl`. For example:

```bash
sudo systemctl restart caddy
```

### How to start Caddy as a MacOS Service

**Port-Binding Permission**

Caddy must run as the `root` user in order to bind to ports 80 and 443.

**launchd plist**

You can use [`serviceman`](https://webinstall.dev/serviceman) to create and
start the appropriate service launcher file for MacOS.

Install Serviceman with Webi:

```bash
webi serviceman
```

Use Serviceman to create a _launchd_ plist file.

```bash
serviceman add --username $(whoami) --name caddy -- \
    caddy run --config ./Caddyfile
```

This will create `~//Library/LaunchAgents/caddy.plist`, which can be managed
with `launchctl`. For example:

```bash
launchctl unload -w "$HOME/Library/LaunchAgents/caddy.plist"
launchctl load -w "$HOME/Library/LaunchAgents/caddy.plist"
```

### How to start Caddy as a Windows Service

You may need to update the Windows Firewall to allow traffic through to Caddy.
You'll also need to create a Startup entry in the registry, which can be done
with Serviceman.

**Windows Firewall**

You can use PowerShell to update the firewall, which looks something like this:

```pwsh
powershell.exe -WindowStyle Hidden -Command $r = Get-NetFirewallRule -DisplayName 'Caddy Web Server' 2> $null; if ($r) {write-host 'found rule';} else {New-NetFirewallRule -DisplayName 'Go Web Server' -Direction Inbound C:\\Users\\YOUR_USER\\.local\\bin\\caddy.exe -Action Allow}
```

**Startup Registry**

You can use [Serviceman](https://webinstall.dev/serviceman) to create and start
the appropriate service launcher for Windows 10.

Install Serviceman with Webi:

```bash
webi.bat serviceman
```

Use Serviceman to create a Startup entry in the Windows Registry:

```bash
serviceman.exe add --name caddy -- \
    caddy run --config ./Caddyfile
```

You can manage the service directly with Serviceman. For example:

```bash
serviceman stop caddy
serviceman start caddy
```
