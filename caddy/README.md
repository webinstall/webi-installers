---
title: Caddy
homepage: https://github.com/caddyserver/caddy
tagline: |
  Caddy is a fast, multi-platform web server with automatic HTTPS.
---

To update or switch versions, run `webi caddy@stable` (or `@v2.4`, `@beta`,
etc).

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
  - Windows

### How to serve a directory

```sh
caddy file-server --browse --listen :4040
```

### How to serve HTTPS on localhost

Caddy can be used to test with https on localhost.

`Caddyfile`:

```Caddyfile
localhost {
    handle /api/* {
        reverse_proxy localhost:3000
    }

    handle /* {
        root * ./public/
        file_server
    }
}
```

```sh
caddyfile run --config ./Caddyfile
```

### How to redirect and reverse proxy

Here's what a fairly basic `Caddyfile` looks like:

`Caddyfile`:

```Caddyfile
# redirect www to bare domain
www.example.com {
    redir https://example.com{uri} permanent
}

example.com {
    ###########
    # Logging #
    ###########

    # log to stdout, which is captured by journalctl
    log {
        output stdout
        format console
    }

    ###############
    # Compression #
    ###############

    # turn on standard streaming compression
    encode gzip zstd

    ####################
    # Reverse Proxying #
    ####################

    # reverse proxy /api to :3000
    handle /api/* {
        reverse_proxy localhost:3000
    }

    # reverse proxy some "well known" APIs
    handle /.well-known/openid-configuration {
        reverse_proxy localhost:3000
    }
    handle /.well-known/jwks.json {
        reverse_proxy  localhost:3000
    }

    ##################
    # Path Rewriting #
    ##################

    # reverse proxy and rewrite path /api/oldpath/* => /api/newpath/*
    handle_path /api/oldpath/* {
        rewrite * /api/newpath{path}
        reverse_proxy localhost:3000
    }

    ###############
    # File Server #
    ###############

    # serve static files
    handle /* {
        root * /srv/example.com/public/
        file_server
    }
}
```

```sh
caddyfile run --config ./Caddyfile
```

- [`log`](https://caddyserver.com/docs/caddyfile/directives/log)
- [`encode`](https://caddyserver.com/docs/caddyfile/directives/encode)
- [`handle`](https://caddyserver.com/docs/caddyfile/directives/handle)
- [`handle_path`](https://caddyserver.com/docs/caddyfile/directives/handle_path)
- [`root`](https://caddyserver.com/docs/caddyfile/directives/root)
- [`file_server`](https://caddyserver.com/docs/caddyfile/directives/file_server)

### How to rewrite and reverse proxy

```Caddyfile
example.com {
    # ...

    # reverse proxy /api/new/ to http://localhost:3100/api/
    handle_path /api/new/* {
        rewrite * /api{path}
        reverse_proxy localhost:3100
    }
}
```

### How to run caddy

```sh
caddy run --config ./Caddyfile
```

Note: `run` runs in the foreground, `start` starts a service (daemon) in the
background.

### How to start Caddy as a Linux service

Here are the 3 things you need to do to start Caddy as a system service:

**a non-root user**

If you don't have a non-root user, consider adding the `app` user with
[`ssh-adduser`](https://webinstall.dev/ssh-adduser).

Using a user named `app` to run your services is common industry convention.

**port-binding privileges**

You can use `setcap` to allow Caddy to use privileged ports.

```sh
sudo setcap cap_net_bind_service=+ep $(readlink -f $(command -v caddy))
```

**systemd config**

You can use [`serviceman`](https://webinstall.dev/serviceman) to create and
start the appropriate systemd launcher for Linux.

Install Serviceman with Webi:

```sh
webi serviceman
```

Use Serviceman to create a _systemd_ config file.

```sh
sudo env PATH="$PATH" \
    serviceman add --system --username $(whoami) --name caddy -- \
        caddy run --config ./Caddyfile
```

This will create `/etc/systemd/system/caddy.service`, which can be managed with
`systemctl`. For example:

```sh
sudo systemctl restart caddy
```

### How to start Caddy as a MacOS Service

**Port-Binding Permission**

Caddy must run as the `root` user in order to bind to ports 80 and 443.

**launchd plist**

You can use [`serviceman`](https://webinstall.dev/serviceman) to create and
start the appropriate service launcher file for MacOS.

Install Serviceman with Webi:

```sh
webi serviceman
```

Use Serviceman to create a _launchd_ plist file.

```sh
serviceman add --username $(whoami) --name caddy -- \
    caddy run --config ./Caddyfile
```

This will create `~//Library/LaunchAgents/caddy.plist`, which can be managed
with `launchctl`. For example:

```sh
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
the appropriate service launcher for Windows.

Install Serviceman with Webi:

```sh
webi.bat serviceman
```

Use Serviceman to create a Startup entry in the Windows Registry:

```sh
serviceman.exe add --name caddy -- \
    caddy run --config ./Caddyfile
```

You can manage the service directly with Serviceman. For example:

```sh
serviceman stop caddy
serviceman start caddy
```
