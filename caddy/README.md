---
title: Caddy
homepage: https://github.com/caddyserver/caddy
tagline: |
  Caddy is a fast, multi-platform web server with automatic HTTPS.
---

To update or switch versions, run `webi caddy@stable` (or `@v2.7`, `@beta`,
etc).

### Files

These are the files / directories that are created and/or modified with this
install:

```text
~/.config/envman/PATH.env
~/.local/bin/caddy

~/.config/caddy/autosave.json
~/.config/caddy/env
~/.local/share/caddy/certificates/
<PROJECT-DIR>/Caddyfile
```

## Cheat Sheet

> Caddy makes it easy to use Let's Encrypt to handle HTTPS (TLS/SSL) and to
> reverse proxy APIs and WebSockets to other apps - such as those written node,
> Go, python, ruby, and PHP.

We've split what we find most useful into two categories:

- **Caddy for Developers** (Caddyfile)
  - Serve Static Files & Directories
  - React's Client-Side Routing
  - Hosting a Single File
  - Warning-free HTTPS on localhost
  - Redirect (ex: www, https)
  - Logging
  - Compression
  - Reverse Proxy
  - Rewrite Paths
  - CORS
  - Wildcard Domain Example (with DuckDNS)
  - TLS on Private DNS (192.168.x.x)
  - Variables, Placeholders, Macros, Snippets
  - Conditional Logic (`if`)
  - **Comprehensive Caddyfile Example**
  - As a macOS service (`launchd` & `launchctl`)
  - As a Windows service (starup item)
  - As a Linux service (`systemd` & `systemctl`)
- **Caddy for DevOps** (JSON Config & API)
  - JSON Config Overview
  - fmt & lint the Caddyfile
  - Caddyfile to JSON Config
  - JSON Config Admin
    - Code Editor autocomplete
    - Backup
    - Restore
    - Manage & Update Config
  - How to use ENVs
  - HTTP Basic Authorization
  - Prevent Dev Sites from Hijacking Production SEO
  - Wildcard & Private IP Certs
    - `libdns` DNS Providers
    - `lego` DNS Providers
  - Use HTTP _only_ (no TLS/HTTPS)
  - Use Non-Standard Ports
  - Permission to Use Ports 80 & 443
  - Run with `systemd` (VM, VPS)
  - Run with `openrc` (Container, Docker)

## Caddy for Developers

```sh
mkdir -p ~/.config/caddy/
touch ~/.config/caddy/env

caddy run --config ./Caddyfile --envfile ~/.config/caddy/env
```

- `run` runs in the foreground
- `start` starts a background service (daemon)

**Warning**: `~/.config/caddy/autosave.json` is _overwritten_ each time `caddy`
is run with a Caddyfile!

See also:

- [Wiki Guides][wiki]: <https://caddy.community/c/wiki/13>

[wiki]: https://caddy.community/c/wiki/13
[cel]:
  https://github.com/google/cel-spec/blob/master/doc/langdef.md#list-of-standard-definitions
[concepts]: https://caddyserver.com/docs/caddyfile/concepts#structure
[encode]: https://caddyserver.com/docs/caddyfile/directives/encode
[file]: https://caddyserver.com/docs/json/apps/http/servers/routes/match/file/
[file_server]: https://caddyserver.com/docs/caddyfile/directives/file_server
[file-server]: https://caddyserver.com/docs/command-line#caddy-file-server
[handle]: https://caddyserver.com/docs/caddyfile/directives/handle
[handle_path]: https://caddyserver.com/docs/caddyfile/directives/handle_path
[http]: https://caddyserver.com/docs/json/apps/http/#docs
[import]: https://caddyserver.com/docs/caddyfile/directives/import
[log]: https://caddyserver.com/docs/caddyfile/directives/log
[matchers]: https://caddyserver.com/docs/caddyfile/matchers#named-matchers
[placeholders]: https://caddyserver.com/docs/caddyfile/concepts#placeholders
[placeholders2]: https://caddyserver.com/docs/conventions#placeholders
[snippets]: https://caddyserver.com/docs/caddyfile/concepts#snippets
[redir]: https://caddyserver.com/docs/caddyfile/directives/redir
[reverse_proxy]: https://caddyserver.com/docs/caddyfile/directives/reverse_proxy
[rewrite]: https://caddyserver.com/docs/caddyfile/directives/rewrite
[root]: https://caddyserver.com/docs/caddyfile/directives/root
[tls]: https://caddyserver.com/docs/caddyfile/directives/tls
[trusted_proxies]:
  https://caddyserver.com/docs/caddyfile/options#trusted-proxies

### How to Serve Files & Directories

Using the convenience `file-server` command:

```sh
caddy file-server --browse --listen :4040
```

Using `Caddyfile`:

```Caddyfile
localhost {
    # ...

    handle /* {
        root * ./public/
        file_server {
            browse
        }
    }
}
```

- `browse` enables the built-in directory explorer

See also:

- [CLI: file-server][file-server]:
  <https://caddyserver.com/docs/command-line#caddy-file-server>
- [`handle`][handle]: <https://caddyserver.com/docs/caddyfile/directives/handle>
- [`root`][root]: <https://caddyserver.com/docs/caddyfile/directives/root>
- [`file_server`][file_server]:
  <https://caddyserver.com/docs/caddyfile/directives/file_server>

### How to handle React's Client-Side Routing

React utilizez client-side routing, which requires Caddy to use certain server configurations.
This is a result of React not following HTTP and HTML standards when handling URLs, as it needs
to serve index.html.

The following configuration will follow a waterfall system to ensure that all special routes
are handled correctly:

```Caddyfile
localhost {
    # ...
    # Proxies API requests
    handle /api/* {
        reverse_proxy localhost:3000
    }

    # Serves static assets
    handle_path /assets/* {
        root * ./build/
        file_server
    }

    # Handles dynamic routing
    handle /* {
        root * ./public/
        file_server {
            browse
        }
    }
}
```

Steps taken:
1. Proxies the API requests to the backend server, or fails with 404 error.
2. Serves the static assets from the ./build/assets/ directory, or fails with 404 error.
3. Handles other types of requests by attempting to serve the file directly, and falls back to
   index.html for client-side routing (never fails with 404 error).

### Hosting a Single File

Caddy can be used to host a single file. This can be done by serving a specific route
for the file, or by using a generic handler with a rewrite rule that points to an HTML
file. 

1. Specific Route with Single File:

This approach is helpful when there is a specific endpoint (in this case /thing) and a
single file (thing.txt).
  
  ```Caddyfile
  localhost {
      # ...
      handle /thing {
          rewrite * ./thing.txt
          root * ./build/
          file_server
      }
  }
  ```

2. Generic Routing with Rewriting:

This approach uses a rewrite rule for /thing to point directly an HTML file in the directory. 
This is more flexible if multiple files and routes are going to be implemented later.
  
  ```Caddyfile
  localhost {
      # ...
      handle /* {
        rewrite /thing ./things/thing-1.html
        root * ./build/
        file_server
      }
  }
  ```

### How to serve HTTPS on localhost

Caddy can be used to test with https on localhost.

It's fully _automatic_ and works in your local browser **without warnings**,
assuming you accept the prompt to add the temporary root certificate to your OS
keychain.

`Caddyfile`:

```Caddyfile
localhost {
    handle /api/* {
        reverse_proxy localhost:3000
    }

    handle /* {
        root * ./public/
        file_server {
            # ...
        }
    }
}
```

```sh
caddy run --config ./Caddyfile
```

See also:

- [`handle`][handle]: <https://caddyserver.com/docs/caddyfile/directives/handle>
- [`root`][root]: <https://caddyserver.com/docs/caddyfile/directives/root>
- [`file_server`][file_server]:

### How to Redirect www and HTTPS

HTTPS redirects are _automatic_.

www redirects can be done like this:

```Caddyfile
# redirect www to apex domain
www.example.com {
    redir https://example.com{uri} permanent
}

example.com {
    # ...
}
```

If you have legacy systems that require the reverse, perhaps to deal with legacy
cookie policies, you can do that too.

See also:

- [`redir`][redir]: <https://caddyserver.com/docs/caddyfile/directives/redir>

### How to Log to System Logger

```Caddyfile
example.com {
    # log to stdout, which is captured by journalctl, etc
    log {
        output stdout
        format console
    }

    # ...
}
```

See also:

- [`log`][log]: <https://caddyserver.com/docs/caddyfile/directives/log>

### How to Enable Compression

```Caddyfile
example.com {

    # enable streaming compression
    encode gzip zstd

    handle /* {
        file_server {
            root /srv/example.com/public/

            # enable static compression
            precompressed br,gzip
        }
    }

    # ...
}
```

- `precompressed` will serve `index.html.br` (or `index.html.gz`) instead of
  `index.html`, when available
  - Why [not zstd][caniusezstd]?
    - [brotli is best][caniusebr] for precompressed (static files)
    - [gzip is best][caniusegz] for streaming (JSON API).

[caniusebr]: https://caniuse.com/?search=brotli
[caniusegz]: https://caniuse.com/?search=gzip
[caniusezstd]: https://caniuse.com/?search=zstd

See also:

- [`encode`][encode]: <https://caddyserver.com/docs/caddyfile/directives/encode>
- [`root`][root]: <https://caddyserver.com/docs/caddyfile/directives/root>
- caniuse | zstd: <https://caniuse.com/?search=zstd>

### How to Reverse Proxy

- `X-Forwarded-*` are set by default:
  - `X-Forwarded-For` (XFR) is the _Request IP_
  - `X-Forwarded-Proto` (XFP) is set to `http` for plaintext or `https` for TLS
  - `X-Forwarded-Host` (XFH) is the original `Host` header from the client
- `trusted_proxies` can be set to allow header pass thru from another proxy
  - `private_ranges` is a built-in alias for \
    `192.168.0.0/16 172.16.0.0/12 10.0.0.0/8 127.0.0.1/8 fd00::/8 ::1`
- `X-Accel-Redirect` can be set to allow static file passthru serving (also
  known as `X-SendFile` or `X-LIGHTTPD-send-file`)

```Caddyfile
{
    servers {
        trusted_proxies static private_ranges
    }
}

example.com {
    # ...

    handle /api/* {
        reverse_proxy localhost:3000 {

            @accel header X-Accel-Redirect *
            handle_response @sendfile {
                root * /srv/assets
                rewrite * {http.response.header.X-Accel-Redirect}
                file_server
            }

        }
    }
}
```

See also:

- [`reverse_proxy#headers`][reverse_proxy]:
  <https://caddyserver.com/docs/caddyfile/directives/reverse_proxy#headers>
- [`trusted_proxies`][trusted_proxies]:
  <https://caddyserver.com/docs/caddyfile/options#trusted-proxies>
- <https://github.com/caddyserver/caddy/pull/4021>
- <https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/X-Forwarded-For>
- <https://www.nginx.com/resources/wiki/start/topics/examples/x-accel/>
- <https://www.nginx.com/resources/wiki/start/topics/examples/xsendfile/>
- <https://tn123.org/mod_xsendfile/>

### How to Rewrite Paths

Rather than `reverse_proxy`, this could just as well be handled by
`file_server`.

`handle_path` _eats_ the path, whereas `handle` _matches_ without consuming.

```Caddyfile
example.com {
    # ...

    # {host}/api/oldpath/* => http://localhost:3000/api/newpath/*
    handle_path /api/oldpath/* {
        rewrite * /api/newpath{path}
        reverse_proxy localhost:3000
    }
}
```

### How to handle CORS Preflight + Request

CORS comes in 3 basic varieties:

- Simple Requests
- Preflight Requests
- Credentialed Requests \
  (by `Origin` and/or `Authentication`)

#### "Simple Requests"

[Simple Requests](https://developer.mozilla.org/en-US/docs/Web/HTTP/CORS#simple_requests)
are those that match:

- `GET`, `HEAD`, or `POST`
- `Accept`, `Range` and traditional `Content-Type`s, which are: \
  - `application/x-www-form-urlencoded`, `multipart/form-data`, `text/plain`

Typical use cases include

- Static Files
- Public Assets
- Contact Request Forms

```Caddyfile
# CORS "Simple Request"
# (for Static Files & Form Posts)
(cors-simple) {
    @match-cors-request-simple {
        not header Origin "{http.request.scheme}://{http.request.host}"
        header Origin "{http.request.header.origin}"
        method GET HEAD POST
    }

    handle @match-cors-request-simple {
        header {
            Access-Control-Allow-Origin "*"
            Access-Control-Expose-Headers *
            defer
        }
    }
}

example.com {
    # ex: POST to unauthenticated forms
    handle /api/public/* {
        import cors-simple
        reverse_proxy localhost:3000
    }

    # ex: GET, HEAD static assets
    handle /* {
        import cors-simple
        file_server {
            /srv/public/
        }
    }
}
```

#### API Requests

Typical use cases for this are:

- Fully Public APIs
- APIs Authenticated by Token or username
  - `Authentication: Basic <base64(api:token)>`
  - `Authentication: Bearer <token>`
- `POST` forms with non-traditional `Content-Types`using
  - `application/json`
  - `application/graphql+json`
  - etc

Important Notes:

- `*` wildcards may NOT be used for authenticated API requests
- `Access-Control-Expose-Headers` exposes to _JavaScript_, not just the browser

```Caddyfile
# CORS Preflight (OPTIONS) + Request (GET, POST, PATCH, PUT, DELETE)
(cors-api) {
    @match-cors-api-preflight {
        not header Origin "{http.request.scheme}://{http.request.host}"
        header Origin "{http.request.header.origin}"
        method OPTIONS
    }
    handle @match-cors-api-preflight {
        header {
            Access-Control-Allow-Origin "{http.request.header.origin}"
            Access-Control-Allow-Methods "GET, POST, PUT, PATCH, DELETE, OPTIONS"
            Access-Control-Allow-Headers "Origin, Accept, Authorization, Content-Type, X-Requested-With"
            Access-Control-Allow-Credentials "true"
            Access-Control-Max-Age "3600"
            defer
        }
        respond "" 204
    }

    @match-cors-api-request {
        not header Origin "{http.request.scheme}://{http.request.host}"
        header Origin "{http.request.header.origin}"
        not method OPTIONS
    }
    handle @match-cors-api-request {
        header {
            Access-Control-Allow-Origin "{http.request.header.origin}"
            Access-Control-Allow-Credentials "true"
            Access-Control-Max-Age "3600"
            defer
        }
    }
}

api.example.com {
    handle /api/* {
        import cors-api

        reverse_proxy localhost:3000
    }

    # ...
}
```

#### Restricted by Origin

Typical use cases for this are:

- Allow access to partners or sister domains

Important Notes:

- `*` wildcards can be used for unauthenticated requests

```Caddyfile
(cors-origin) {
    @match-cors-preflight-{args.0} {
        header Origin "{args.0}"
        method OPTIONS
    }
    handle @match-cors-preflight-{args.0} {
        header {
            Access-Control-Allow-Origin "{args.0}"
            Access-Control-Allow-Methods "GET, POST, PUT, PATCH, DELETE, OPTIONS"
            Access-Control-Allow-Headers *
            Access-Control-Max-Age "3600"
            defer
        }
        respond "" 204
    }

    @match-cors-request-{args.0} {
        header Origin "{args.0}"
        not method OPTIONS
    }
    handle @match-cors-request-{args.0} {
        header {
            Access-Control-Allow-Origin "{http.request.header.origin}"
            Access-Control-Expose-Headers *
            defer
        }
    }
}

partners.example.com {
    import cors-origin https://member.example.com
    import cors-origin https://whatever.com

    file_server {
        root /srv/public/
    }
}
```

See also:

- [`import`][import]: <https://caddyserver.com/docs/caddyfile/directives/import>
- <https://httptoolkit.com/will-it-cors/source-url>
- <https://gist.github.com/ryanburnette/d13575c9ced201e73f8169d3a793c1a3>
- <https://kalnytskyi.com/posts/setup-cors-caddy-2/>
- <https://caddyserver.com/docs/caddyfile/directives/import#examples>
- <https://developer.mozilla.org/en-US/docs/Web/HTTP/CORS#preflighted_requests>
- <https://developer.mozilla.org/en-US/docs/Glossary/Preflight_request>

<!--
v1 only: https://enable-cors.org/server_caddy.html
-->

### How to Wildcards & Private DNS

DNS Providers are required for

- wildcards (`*.example.com`)
- Private IPs / Private DNS (`192.168.x.x`)
- Running Caddy directly on non-standard ports (`3000`, `8443`)

Example with DuckDNS:

1. Put the credentials in your dotenv (the name is arbitrary): \
   `caddy.env`:
   ```sh
   MY_DUCKDNS_TOKEN=xxxxxxxx-xxxx-4xxx-8xxx-xxxxxxxxxxxx
   ```
2. Add the `tls` directive in the format of
   `dns <provider> [documented params]`:

   ```Caddyfile
   # a wildcard domain
   *.example.duckdns.org {
       tls {
           dns duckdns {env.MY_DUCKDNS_TOKEN}
       }

       # ...
   }

   # an intranet domain (on a private network, such as 192.168.x.x)
   local.example.duckdns.org {
       tls {
           dns duckdns {env.MY_DUCKDNS_TOKEN}
       }

       # ...
   }
   ```

For more information see **How to use libdns providers** below in the DevOps
section.

See also:

- [`tls`][tls]: <https://caddyserver.com/docs/caddyfile/directives/tls>
- <https://github.com/caddy-dns>
- <https://caddyserver.com/docs/modules/> (search `dns.providers`)
- <https://github.com/go-acme/lego#dns-providers>
- <https://caddyserver.com/docs/modules/dns.providers.lego_deprecated>

### How to use Caddyfile Meta Variables

- "Placeholders" and "Shorthand" are the variables that look like:
  - `{http.request.uri}`
  - `{request.uri}`
  - `{uri}`
  - `{path}`
  - `{host}`
  - `{http.response.header}`
  - `{args[0]}`
- Environment Variables come in Parse-time and Runtime variety:
  - `{$DUCKDNS_API_TOKEN}`, `{$BASIC_AUTH_DIGEST}` (parse-time)
  - `{env.DUCKDNS_API_TOKEN}`, `{env.BASIC_AUTH_DIGEST}` (runtime)
- "Named Matchers" can substitute paths in most places:

  ```diff
  # match this secret path to find hidden treasures
  handle_path /easter-eggs/* {
      root * /srv/my-eggs
      file_server
  }

  # match this secret header to find hidden treasures
  @my-easter-egg {
      header X-Magic-Word "Easter-Egg"
  }
  handle @my-easter-egg {
      root * /srv/my-eggs
      file_server
  }
  ```

- "Imports" and "Snippets" are the macro templates that look like:

  ```Caddyfile
  # (template-name)
  (my-no-plaintext) {

    # @matcher-name
    @my-plaintext {
        protocol http
    }

    # use of matcher
    redir @my-plaintext https://{host}{uri}
  }

  example.com {
      # import the snippet
      import my-no-plaintext
  }
  ```

See also:

- [Overview][concepts]:
  <https://caddyserver.com/docs/caddyfile/concepts#structure>
- [Placeholders][placeholders]:
  <https://caddyserver.com/docs/caddyfile/concepts#placeholders>
- [Snippets][snippets]:
  <https://caddyserver.com/docs/caddyfile/concepts#snippets>

### Placeholder Hierarchy

```text
Path                                        # Shorthand
├── args[]                                  # in snippets (template functions)
├── env.*
├── http
│   ├── error.+                             # {err.+}
│   ├── matchers
│   │   ├── file.+                          # {file_match.+}
│   │   ├── header_regexp.?
│   │   ├── path_regexp.?
│   │   └── vars_regexp.?
│   ├── regexp.*[]                          # {re.*.1}
│   ├── request
│   │   ├── cookie.*                        # {cookie.*}
│   │   ├── header.*                        # {header.*}
│   │   ├── host
│   │   │   └── labels[]                    # {labels.0} (as rDNS: com.example)
│   │   ├── hostport                        # {hostport}
│   │   ├── method                          # {method}
│   │   ├── port                            # {port}
│   │   ├── remote                          # {remote}
│   │   │   ├── host                        # {remote_host}
│   │   │   └── port                        # {remote_port}
│   │   ├── scheme                          # {scheme}
│   │   ├── tls
│   │   │   ├── cipher_suite                # {tls_cipher}
│   │   │   ├── client
│   │   │   │   ├── certificate_der_base64  # {tls_client_certificate_der_base64}
│   │   │   │   ├── certificate_pem         # {tls_client_certificate_pem}
│   │   │   │   ├── fingerprint             # {tls_client_fingerprint}
│   │   │   │   ├── issuer                  # {tls_client_issuer}
│   │   │   │   ├── serial                  # {tls_client_serial}
│   │   │   │   └── subject                 # {tls_client_subject}
│   │   │   └── version                     # {tls_version}
│   │   ├── uri                             # {uri}
│   │   │   ├── path.+                      # {path.+}
│   │   │   │   ├── dir                     # {dir}
│   │   │   │   └── file.+                  # {file}
│   │   │   │       ├── base                # {file.base}
│   │   │   │       └── ext                 # {file.ext}
│   │   │   └── query.*                     # {query.*}
│   ├── reverse_proxy.+                     # {rp.+}
│   │   └── upstream                        # {upstream}
│   │   │   └── hostport                    # {upstream_hostport}
│   └── vars.*                              # {vars.*}
│       └── client_ip                       # {client_ip}
├── system
│   ├── hostname
│   ├── slash
│   ├── os
│   ├── arch
│   └── wd
└── time
    └── now
        ├── common_log
        ├── http
        ├── unix
        ├── unix_ms
        └── year
```

- `[]` signifies a list accessible by index, such as `labels.0`
- `.+` signifies more pre-defined keys, see docs (linked below) for specifics
- `.*` signifies that the keys are arbitrary per the config or the request
- `.?` signifies that we didn't understand the documentation

See also:

- [Concepts: Placeholders][placeholders]:
  <https://caddyserver.com/docs/caddyfile/concepts#placeholders>
- [Conventions: Placeholders][placeholders2]:
  <https://caddyserver.com/docs/conventions#placeholders>
- [`http`][http]: <https://caddyserver.com/docs/json/apps/http/#docs>
- [`file`][file]:
  <https://caddyserver.com/docs/json/apps/http/servers/routes/match/file/>

### How to Conditional ENVs

There is no `if` in Caddy, but a _matcher_ with "CEL" does the same thing.

Ex: I only want to enforce HTTP Basic Auth if it's enabled:

```Caddyfile
localhost {
    @match-enforce-auth `"{$HTTP_BASIC_AUTH_ENABLED}".size() > 0`
    basicauth @match-enforce-auth {
        {$HTTP_BASIC_AUTH_USERNAME} {$HTTP_BASIC_AUTH_PASSWORD_DIGEST}
    }

    # ...
}
```

You can do slightly more complex expressions on the variety of variables
(_placeholders_), but you'd have to look up the [CEL docs]().

However, you can only do these expressions in things that have a _matcher_.

See also:

- [`matchers`](matchers):
  <https://caddyserver.com/docs/caddyfile/matchers#named-matchers>
- [CEL][cel]:
  <https://github.com/google/cel-spec/blob/master/doc/langdef.md#list-of-standard-definitions>

### Putting it All Together

Here's what a fairly basic, but comprehensive and complete `Caddyfile` looks
like:

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
        file_server {
            precompressed br,gzip
        }
    }
}
```

### How to run Caddy as a macOS Service

To avoid the nitty-gritty details of `launchd` plist files, you can use
[`serviceman`](../serviceman/) to template out the plist file for you:

1. Install [`serviceman`](../serviceman/)
   ```sh
   webi serviceman
   ```
2. Use Serviceman to create a _launchd_ plist file

   ```sh
   my_username="$(id -u -n)"

   serviceman add --agent --name 'caddy' --workdir ./ -- \
       caddy run --envfile ~/.config/caddy/env --config ./Caddyfile --adapter caddyfile
   ```

   (this will create `~/Library/LaunchAgents/caddy.plist`)

3. Manage the service with `launchctl`
   ```sh
   launchctl unload -w ~/Library/LaunchAgents/caddy.plist
   launchctl load -w ~/Library/LaunchAgents/caddy.plist
   ```

This process creates a _User-Level_ service in `~/Library/LaunchAgents`. To
create a _System-Level_ service in `/Library/LaunchDaemons/` instead:

```sh
serviceman add --name 'caddy' --workdir ./ --daemon -- \
   caddy run --envfile ~/.config/caddy/env --config ./Caddyfile --adapter caddyfile
```

### How to run Caddy as a Windows Service

1. Set a **Windows Firewall Rule** to allow traffic to Caddy. \
   You can do this with _PowerShell_ by changing `YOUR_USER` in the script below
   and running it in `cmd.exe` as Administrator:
   ```pwsh
   powershell.exe -WindowStyle Hidden -Command $r = Get-NetFirewallRule -DisplayName 'Caddy Web Server' 2> $null; if ($r) {write-host 'found rule';} else {New-NetFirewallRule -DisplayName 'Caddy Web Server' -Direction Inbound $HOME\\.local\\bin\\caddy.exe -Action Allow}
   ```
2. Install [`serviceman`](../serviceman/)
   ```sh
   webi serviceman
   ```
3. Create a **Startup Registry Entry** with Serviceman.
   ```sh
   serviceman.exe add --name caddy -- \
       caddy run --envfile ~/.config/caddy/env --config ./Caddyfile --adapter caddyfile
   ```
4. You can manage the service directly with Serviceman. For example:
   ```sh
   serviceman stop caddy
   serviceman start caddy
   ```

This will run caddy as a _Startup Item_. To run as a true system service see
<https://caddyserver.com/docs/running#windows-service>.

### How to run Caddy as a Linux service

This will create a **System Service** using `Caddyfile`. \
See the notes below to run as a **User Service** or use the JSON Config.

1. If you haven't already, create **a non-root user**. You can use `ssh-adduser`
   for this:
   ```sh
   curl -fsS https://webi.sh/ssh-adduser | sh
   ```
   (this will follow the common industry convention of naming the user `app`)
2. Give `caddy` **port-binding privileges**. You can use
   [`setcap-netbind`](../setcap-netbind/) for this:

   ```sh
   webi setcap-netbind
   setcap-netbind caddy
   ```

   (or you can use `setcap` directly)

   ```sh
   my_caddy_path="$( command -v caddy )"
   my_caddy_absolute="$( readlink -f "${my_caddy_path}" )"

   sudo setcap cap_net_bind_service=+ep "${my_caddy_absolute}"
   ```

3. Install [`serviceman`](../serviceman/) to template a **systemd service unit**
   ```sh
   webi serviceman
   ```
4. Use Serviceman to create a _systemd_ config file.
   ```sh
   serviceman add --name 'caddy' --daemon -- \
       caddy run --envfile ~/.config/caddy/env --config ./Caddyfile --adapter caddyfile
   ```
   (this will create `/etc/systemd/system/caddy.service`)
5. Manage the service with `systemctl` and `journalctl`:
   ```sh
   sudo systemctl restart caddy
   sudo journalctl -xefu caddy
   ```

To create a **User Service** instead:

- use `--agent` when running `serviceman`:
  ```sh
  serviceman add --agent --name caddy -- \
      caddy run --envfile ~/.config/caddy/env --config ./Caddyfile --adapter caddyfile
  ```
  (this will create `~/.config/systemd/user/`)
- user the `--user` flag to manage services and logs:
  ```sh
  systemctl --user enable caddy
  systemctl --user restart caddy
  journalctl --user -xef -u caddy
  ```

To use the **JSON Config**:

- use `--resume` rather than `--config ./Caddyfile`
  ```sh
  caddy run --resume --envfile ~/.config/caddy/env
  ```

## Caddy for DevOps

```sh
touch ./config.env

caddy run --resume --envfile ./caddy.env
# (resumes from ~/.config/caddy/autosave.json)
```

- `--resume` overrides `--config`
- the save file is hard coded to `~/.config/caddy/autosave.json`
- only a single API-enabled instance can resumed at a time \
  (the workaround is to not use resume, but replace the config file and restart)

To create and load the initial JSON Config, see the _**Caddyfile to JSON**_
section below.

### Where to learn about the JSON config

The best way to learn is to create a `Caddyfile` and

- run `caddy adapt ./Caddyfile`
- or see `~/.config/caddy/autosave.json` after _any_ `caddy run`

Then it's also helpful to read the general overview:

- <https://caddy.community/t/writing-a-caddy-json-config-from-scratch/7524>
- <https://caddyserver.com/docs/json/>

The key things you'll need to learn:

- which modules can be nested within others (`handle`, `routes`)
- which keys are arbitrary (`srv0`) and which are pre-defined (`group`, `match`)
- which structures are core to caddy vs which are specific to a module
- which structures you can **eliminate or deneste** (`Caddyfile` conversion is
  messy)

### How to fmt & lint Caddyfiles

Both `caddy fmt` and `caddy adapt` can be used to lint.

```sh
caddy fmt --overwrite ./Caddyfile
```

```sh
caddy adapt --config ./Caddyfile
```

### How to convert Caddyfile to JSON

Shown with [`jq`](../jq/) ([`yq`](../yq/) also works well) because it makes the
output readable.

```sh
caddy adapt --config ./Caddyfile |
    jq > ./caddy.json
```

You can then load the JSON Config to a live server:

```sh
my_config="./caddy.json"

curl -X POST "http://localhost:2019/load" \
    -H "Content-Type: application/json" \
    -d @"${my_config}"
```

This will immediately overwrite `~/.config/caddy/autosave.json`.

### Code Editor support for Caddy's JSON API

VS Code and Vim / NeoVim are supported.

See <https://github.com/abiosoft/caddy-json-schema>.

### How to Backup the JSON config

```sh
my_date="$( date '+%F_%H.%M.%S' )"

curl "http://localhost:2019/config" -o ./caddy."${my_date}".json
```

Or copy from `~/.config/caddy/autosave.json`

**Warning**: `~/.config/caddy/autosave.json` is _overwritten_ each time `caddy`
is run with a Caddyfile!

### How to Restore via the API

This will effectively gracefully restart caddy.

```sh
my_config="./caddy.json"

curl -X POST "http://localhost:2019/load" \
    -H "Content-Type: application/json" \
    -d @"${my_config}"
```

### How to Update via the API

It will probably be best (and simplest) to write a new config file
programmatically and then upload it whole.

Currently, there is no API to provide idempotent updates ("upsert" or "set"),
and many changes that are logically a single unit (such as adding a new site),
require updates among a few different structures, such as:

- `apps.https.servers["srv0"].routes[]`
- `apps.tls.automation.policies[].subjects`
- `apps.tls.certificates.automate[]`

However, very, very large config files may benefit from the extra work required
to do smaller updates rather than reload the whole config.

Here are some important notes:

- `PATCH` will **replace**, not modify / merge as you would traditionally expect
- `PUT` will **NOT** replace, but rather _insert_ into a position
- A literal `...` in a path, such as `POST /config/my-config/...` will _append_
- `@id` may exist as a special key on _any_ object, but must _globally_ unique
- `GET /id/my_object` directly accesses the object with `"@id": "my_object"`

See also:

- <https://caddyserver.com/docs/api>
- <https://caddyserver.com/docs/api-tutorial>

### How to use ENVs

Caddy's `--envfile ./caddy.env` parser supports dotenvs in this format:

`caddy.env`:

```text
FOO="one"
BAR='two'
BAZ=three
```

They are accessed like `{env.FOO}` whether in `Caddyfile` or `caddy.json`:

```Caddyfile
example.com {
    file_server * {
        root {env.WWW_ROOT}
    }
}
```

```json
{
  "apps": {
    "http": {
      "servers": {
        "my-srv0": {
          "listen": [":443"],
          "routes": [
            {
              "match": [{ "host": ["example.com"] }],
              "handle": [
                {
                  "handler": "file_server",
                  "root": "{env.WWW_ROOT}"
                }
              ],
              "terminal": true
            }
          ]
        }
      }
    }
  }
}
```

Conventionally, the dotenv file should be placed in one of the following
locations:

- `~/.config/caddy/env`
- `<PROJECT-DIR>/caddy.env`
- `<PROJECT-DIR>/.env`

It does _NOT_ follow the [dotenv][dotenv-rb] [spec][posix-vars], in particular:

- does not support `export ` prefix
- does not interpolate variables in double-quoted `"` strings

Consider [dotenv](../dotenv) for better compatibility.

See also:

- <https://github.com/bkeepers/dotenv>
- <https://pubs.opengroup.org/onlinepubs/9699919799/utilities/V3_chap02.html#tag_18_05_03>

[dotenv-rb]: https://github.com/bkeepers/dotenv
[posix-vars]:
  https://pubs.opengroup.org/onlinepubs/9699919799/utilities/V3_chap02.html#tag_18_05_03

### How to add HTTP Basic Authorization

1. Digest a password with random salt
   ```sh
   cat ./password.txt |
       caddy hash-password
   ```
   ```text
   $2a$14$QYYeOtsv0RJixoNZ5frOwuPDiUWl8QBkeMEUBbmnkOHuErlVklzTm
   ```
2. Put the digest into an env file with **single quotes** (to escape the `$`s) \
   `caddy.env`:
   ```sh
   BASIC_AUTH_USERNAME=my-username
   BASIC_AUTH_DIGEST='$2a$14$QYYeOtsv0RJixoNZ5frOwuPDiUWl8QBkeMEUBbmnkOHuErlVklzTm'
   ```
3. Reference `{env.BASIC_AUTH_DIGEST}` in the `Caddyfile` or `caddy.json`
   ```Caddyfile
   example.com {
       handle /* {
           basicauth {
               {env.BASIC_AUTH_USERNAME} {env.BASIC_AUTH_DIGEST}
           }
           root * /home/app/srv/example.com/public/
           file_server
       }
   }
   ```

### How to Prevent Dev Sites from Hijacking Prod

Not `caddy` specific, but...

**By default**, dev sites on dev domains will **hijack the SEO** and **damage
the reputation** of your production domains.

Allowing non-production sites to be indexed may even cause browsers to issue
**Suspicious Site Blocking** on your primary domain.

To prevent search engine and browser confusion

- delist your _demo_, _staging_, _beta_, & _development_ from indexing
- promote your primary domain as canonical
- _DO NOT_ prevent crawling via `robots.txt` \
  (counter-intuitive, but pages _must_ be crawled for links to _NOT_ be indexed)
- _all_ domains using public TLS certs _will_ be indexed by default \
  (they are all linked to and crawled from various Certificate Transparency reports)
- follow these guidelines even if the dev sites use HTTP Basic Auth

```Caddyfile
dev.example.com {
    header {
        Link "<https://production.example.com{http.request.orig_uri}>; rel=\"canonical\""
        X-Robots-Tag noindex
    }

    # ...
}
```

See also:

- <https://developers.google.com/search/docs/advanced/robots/intro>
- <https://developers.google.com/search/docs/advanced/crawling/block-indexing>
- <https://certificate.transparency.dev/>
- <https://crt.sh>

### How to DNS Providers for Wildcard Certs

You will need to use [xcaddy](../xcaddy) to **build `caddy` with DNS** module
support.

DNS Providers come in two flavors:

1. `libdns` instances (newer, fewer providers)
   - see <https://github.com/caddy-dns>
   - search `dns.providers` <https://caddyserver.com/docs/modules/>
2. `lego` singletons (deprecated)
   - <https://github.com/go-acme/lego#dns-providers>
   - <https://caddyserver.com/docs/modules/dns.providers.lego_deprecated>

You can only have **ONE** `lego` instance per process, whereas `libdns` can
support multiple providers across multiple domains.

### How to use libdns providers

Look for your DNS provider in the official lists:

- <https://github.com/caddy-dns>
- <https://caddyserver.com/docs/modules/>

For this example we'll use _DuckDNS_ (<https://github.com/caddy-dns/duckdns>).

1. Put the credentials in your dotenv (the name is arbitrary): \
   `caddy.env`:
   ```sh
   MY_DUCKDNS_TOKEN=xxxxxxxx-xxxx-4xxx-8xxx-xxxxxxxxxxxx
   ```
2. Add the `tls` directive in the format of
   `dns <provider> [documented params]`:

   ```Caddyfile
   example.duckdns.org {
       tls {
           dns duckdns {env.MY_DUCKDNS_TOKEN}
       }

       # ...
   }

   *.example.duckdns.org {
       tls {
           dns duckdns {env.MY_DUCKDNS_TOKEN}
       }

       # ...
   }
   ```

When using the **JSON config** the `token` key is instead named `api_token`!

You can see this by running `caddy adapt ./Caddyfile` on the example above.

### How to use lego providers

If you can't find your DNS provider in the `libdns` list, check to see if it's
available in the [`lego` list][lego-providers]:

- <https://github.com/go-acme/lego#dns-providers>

For this example we'll use _DNSimple_
(<https://go-acme.github.io/lego/dns/dnsimple/>).

1. Put the credentials in your dotenv (which MUST match the docs): \
   `caddy.env`:
   ```sh
   DNSIMPLE_OAUTH_TOKEN=xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
   ```
2. Add the `tls` directive in the format of `dns lego_deprecated <provider>`:

   ```Caddyfile
   example.com {
       tls {
           dns lego_deprecated dnsimple
       }

       # ...
   }

   *.example.com {
       tls {
           dns lego_deprecated dnsimple
       }

       # ...
   }
   ```

[lego-providers]: https://github.com/go-acme/lego#dns-providers

### How to run caddy on HTTP only (no TLS)

You **_must_** use the `http://` prefix AND specify a port number:

```Caddyfile
http://localhost:3080 {
    #...
}
```

### How to run caddy on non-standard ports

```Caddyfile
http://example.com:3080, https://example.com:3443 {
    #...
}
```

You cannot get TLS certificates (HTTPS) on non-standard ports unless:

- you use a DNS Provider (see the _Private IP_ / _Wildcard_ section)
- or you have some sort of special proxy in place

### How to allow caddy to bind on 80 & 443

On macOS all programs are allowed to use privileged ports by default.

On Linux there are several ways to add network _capabilities_ for privileged
ports:

1. Use `setcap-netbind`
   ```sh
   webi setcap-netbind
   setcap-netbind caddy
   ```
2. Use `setcap` directly

   ```sh
   my_caddy_path="$( command -v caddy )"
   my_caddy_absolute="$( readlink -f "${my_caddy_path}" )"

   sudo setcap cap_net_bind_service=+ep "${my_caddy_absolute}"
   ```

3. Use `setcap` through systemd \
   (see systemd instructions below)

4. Run as `root` (such as on single-user containers)
5. Run as `app`, but port-forward through the container \
   (you figure it out)

`setcap-netbind` **must** be run each time caddy is updated.

### How to run with systemd

See also: <https://caddyserver.com/docs/running>

`systemd` is the `init` system used on most VPS-friendly Linuxes.

1. Install `serviceman` to create the `systemd` config
   ```sh
   webi serviceman
   ```
2. Generate the `service` file: \
   - JSON Config
     ```sh
     serviceman add --name 'caddy' --daemon -- \
         caddy run --resume --envfile ./caddy.env
     ```
   - Caddyfile
     ```sh
     serviceman add --name 'caddy' --daemon -- \
         caddy run --config ./Caddyfile --envfile ./caddy.env
     ```
3. Reload `systemd` config files, the logging service (it may not be started on
   a new VPS), and caddy
   ```sh
   sudo systemctl daemon-reload
   sudo systemctl restart systemd-journald
   sudo systemctl restart caddy
   ```

If you prefer to create the `service` file manually, it should look something
like this:

`/etc/systemd/system/caddy.service`:

```ini
# Generated for serviceman. Edit as you wish, but leave this line.
# Pre-req
# sudo mkdir -p ~/srv/ /var/log/caddy/
# sudo chown -R app:app /var/log/caddy
# Post-install
# sudo journalctl -xefu caddy

[Unit]
Description=caddy
After=network-online.target
Wants=network-online.target systemd-networkd-wait-online.service

[Service]
# Restart on crash (bad signal), but not on 'clean' failure (error exit code)
# Allow up to 3 restarts within 10 seconds
# (it's unlikely that a user or properly-running script will do this)
Restart=always
StartLimitInterval=10
StartLimitBurst=3

# User and group the process will run as
User=app
Group=app

WorkingDirectory=/home/app/srv/
ExecStart=/home/app/.local/bin/caddy run --resume --envfile /home/app/srv/caddy.env
TimeoutStopSec=5s
LimitNOFILE=1048576
LimitNPROC=512
PrivateTmp=true
ProtectSystem=full

# These directives allow the service to gain root-like networking privileges.
# Note that you may have to add capabilities required by any plugins in use.
CapabilityBoundingSet=CAP_NET_ADMIN CAP_NET_BIND_SERVICE
AmbientCapabilities=CAP_NET_ADMIN CAP_NET_BIND_SERVICE
NoNewPrivileges=true

# Caveat: Some features may need additional capabilities.
# For example an "upload" may need CAP_LEASE
; CapabilityBoundingSet=CAP_NET_ADMIN CAP_NET_BIND_SERVICE CAP_LEASE
; AmbientCapabilities=CAP_NET_ADMIN CAP_NET_BIND_SERVICE CAP_LEASE
; NoNewPrivileges=true

[Install]
WantedBy=multi-user.target
```

See also:

- <https://github.com/caddyserver/dist/blob/master/init/caddy-api.service>
- <https://github.com/caddyserver/dist/blob/master/init/caddy.service>

### How to run with openrc

See also: <https://caddyserver.com/docs/running>

`openrc` is the `init` system on Alpine and other Docker and
_container-friendly_ Linuxes.

`/etc/init.d/caddy`:

```sh
#!/sbin/openrc-run
supervisor=supervise-daemon

name="Caddy web server"
description="Fast, multi-platform web server with automatic HTTPS"
description_checkconfig="Check configuration"
description_reload="Reload configuration without downtime"

# for JSON Config
: ${caddy_opts:="--envfile /root/.config/caddy/env --resume"}

# for Caddyfile
#: ${caddy_opts:="--envfile /root/.config/caddy/env --config /root/srv/caddy/Caddyfile"}

command=/root/bin/caddy
command_args="run $caddy_opts"
command_user=root:root
extra_commands="checkconfig"
extra_started_commands="reload"
output_log=/var/log/caddy.log
error_log=/var/log/caddy.err

depend() {
    need net localmount
    after firewall
}

checkconfig() {
    ebegin "Checking configuration for $name"
    su ${command_user%:*} -s /bin/sh -c "$command validate $caddy_opts"
    eend $?
}

reload() {
    ebegin "Reloading $name"
    su ${command_user%:*} -s /bin/sh -c "$command reload $caddy_opts"
    eend $?
}

stop_pre() {
    if [ "$RC_CMD" = restart ]; then
        checkconfig || return $?
    fi
}
```
