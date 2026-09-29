---
title: tlsrouter
homepage: https://github.com/bnnanet/tlsrouter
tagline: |
  tlsrouter: A TLS reverse proxy for SNI and ALPN routing.
---

To update or switch versions, run `webi tlsrouter@stable` (or `@v0.11`, `@beta`,
etc).

### Files

These are the files that are created and/or modified with this installer:

```text
~/.config/envman/PATH.env
~/.config/tlsrouter/
~/.local/share/bitwire-it/ipblocklist/
~/.local/bin/tlsrouter
~/.local/opt/tlsrouter-VERSION/bin/tlsrouter
```

## Cheat Sheet

> `tlsrouter` routes TLS traffic to backends by SNI and ALPN. It supports static
> configuration and dynamic IP-based routing.

### Basic usage

Static routes and dynamic IP routes can run together:

```sh
tlsrouter \
  --ip-domains vms.example.net,vms.mypmx.net \
  --networks 192.168.1.0/24,192.168.2.0/24 \
  --config ~/.config/tlsrouter/backends.csv \
  --vault ~/.config/tlsrouter/secrets.tsv \
  --bind 0.0.0.0 \
  --port 443
```

| flag           | purpose                                                 |
| -------------- | ------------------------------------------------------- |
| `--ip-domains` | domains trusted for _direct ip domain_ routing          |
| `--networks`   | are IP ranges allowed to be used in DNS-managed routing |
| `--config`     | file for file-managed routing                           |
| `--vault`      | for additional auth data (ex: HTTP Basic and Bearer)    |

Create `~/.config/tlsrouter/allowed.csv` before relying on the default Bitwire
IT IP blocklist. If the whitelist cannot load, all blacklists are disabled
fail-open.

DNS-managed routing is this simple:

1. Set `CNAME app.example.com tls-192-168-1-100.vms.example.net`
2. TLS termination and SNI+ALPN routing happens automatically:
   - HTTPS => 3080
   - SSH => 22 (requires an sclient)
   - PostgreSQL => 15432 (requires PostgreSQL 17+ and compatible clients)
   - Others => 10000 + registered port (hence postgres is 10000+5432)

## Table of Contents

- [Configuring IP Lists](#configuring-ip-lists)
- [Fixed routing config](#fixed-routing-config)
- [Dynamic routing via CNAME](#dynamic-routing-via-cname)
- [Put Caddy behind tlsrouter](#put-caddy-behind-tlsrouter)
- [Dynamic port mappings](#dynamic-port-mappings)
- [Dynamic Apex routing via A+SRV](#dynamic-apex-routing-via-asrv)
- [Advanced: Raw TCP Proxying (No TLS Termination)](#advanced-raw-tcp-proxying-no-tls-termination)
- [Strict IP Whitelist](#strict-ip-whitelist)
- [Always check the Host header](#always-check-the-host-header)

### Configuring IP Lists

IP list values may be any of:

- Single IP, or Prefix (CIDR)
- A file containing a list of IPs (may have comments)
- A URL to such a file

URLs are cached and updated periodically.

`~/.config/tlsrouter/allowed.csv`:

```tsv
# host or network or filepath or URL
198.51.100.8
203.0.113.0/24
https://trustedips.example.net/list.csv
```

This is an anti-lockout list - matching entries bypass the blacklists.

<small>Note: since the default blacklist is updated every 2 hours and often
includes IPs from common open relays from free cloud services - such as GitHub
actions - that are being used to perpetrate attacks, you may need to add such
free services you use manually.</small>

The whitelist must load successfully or all blacklists are disabled fail-open.

### Fixed routing config

`~/.config/tlsrouter/backends.csv`:

```csv
app_slug,domain,alpn,backend_address,backend_port,terminate_tls,connect_tls,rewrite_host,skip_tls_verify,auth,allowed_client_hostnames
myapp,site.example.com,http/1.1,127.0.0.1,3080,true,false,,,,
```

`secrets.tsv` stores values referenced as `vault://<id>` in `backends.csv` to be
used for additional Basic Auth:

```sh
tabvault ~/.config/tlsrouter/secrets.tsv add
```

### Dynamic routing via CNAME

DNS routes traffic; it does not authorize ownership. Anyone can set DNS records
to point to someone else's server. Use backend configuration and allowed domains
or networks to control what tlsrouter will proxy.

For subdomains, point a CNAME at a dynamic hostname:

```dns
; Terminated TLS, then route by ALPN:
; http/1.1,h2 => 3080, postgresql => 15432, etc
CNAME site.example.com tls-192-168-1-100.vms.example.net 300

; Raw TCP passthrough (http/1.1,h2 => 443, ssh => 44322, etc)
CNAME ssh.example.com tcp-192-168-1-100.vms.example.net 300
```

### Put Caddy behind tlsrouter

Route terminated HTTP traffic to Caddy on port `3080`:

```sh
caddy run --envfile ~/.config/caddy/env --config ./Caddyfile --adapter 'caddyfile'
```

```Caddyfile
{
	admin off
	auto_https off
	http_port 3080
	https_port 0
	servers {
		trusted_proxies static 10.0.0.0/8 172.16.0.0/12 192.168.0.0/16
	}
}

http:// {
	log

	basic_auth {
		myuser {env.MYUSER_HASH}
	}

	handle /api/* {
		reverse_proxy localhost:3081
	}

	root * ./www/public/
	file_server {
		precompressed br gzip zstd
	}
	encode zstd gzip
}
```

### Dynamic port mappings

| Service      | ALPN             | Terminated/plain port |
| ------------ | ---------------- | --------------------: |
| HTTP         | `http/1.1`, `h2` |                  3080 |
| SSH over TLS | `ssh`            |                    22 |
| PostgreSQL   | `postgresql`     |                 15432 |
| MySQL        | `mysql`          |                 13306 |

Dynamic mappings generally use `10000 + common port` for applications that are
not expecting terminated TLS, or that may be unsafe to expose directly. This
helps prevent private networking from being exposed by accident.

See the
[full ALPN and port table](https://github.com/bnnanet/tlsrouter#dynamic-ip-url-mapping).

### Dynamic Apex routing via A+SRV

For an apex domain, use an A record plus SRV records:

```dns
A   myapp.com                              123.1.2.3 300
SRV _http._tcp.myapp.com                   10 3080 tls-10-11-1-123.vms.example.net.myapp.com 300 10
SRV _ssh._tcp.myapp.com                    10 22   tls-10-11-1-123.vms.example.net.myapp.com 300 10
```

The SRV target stays within the same DNS zone as `myapp.com`. SRV records must
use the **exact port** assigned to the ALPN in the port table. Arbitrary **ports
are rejected** for security.

### Advanced: Raw TCP Proxying (No TLS Termination)

Use a `tcp-...` hostname when the backend must receive the original TLS or TCP
stream. No TLS is terminated by tlsrouter. Raw TCP uses the service's normal TLS
port in almost all cases; the exceptions are HTTPS (`443` raw, `3080`
terminated) and SSH (`44322` raw, `22` terminated).

| Service      | ALPN             | Raw/TLS port |
| ------------ | ---------------- | -----------: |
| HTTP         | `http/1.1`, `h2` |          443 |
| SSH over TLS | `ssh`            |        44322 |
| PostgreSQL   | `postgresql`     |         5432 |
| MySQL        | `mysql`          |         3306 |

### Strict IP Whitelist

To make `~/.config/tlsrouter/allowed.csv` function a pure whitelist, block all
IPv4 addresses and add only approved entries to `allowed.csv`:

```sh
tlsrouter \
  --ip-whitelist ~/.config/tlsrouter/allowed.csv \
  --ip-blacklist-extra 0.0.0.0/0
```

### Always check the Host header

As with **any reverse proxy** or web application, any domain owner can point
their domain to your server:

```
CNAME example.evil.site tls-192-168-1-100.vms.example.net 300
```

TLS Router does not make this any better or worse than any other reverse proxy
(Caddy, Traefik, Nginx, etc) - it's just something you should be aware of and
check in your application.
