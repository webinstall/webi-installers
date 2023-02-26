---
title: curlie
homepage: https://github.com/rs/curlie
tagline: |
  curlie wraps `curl` with modern defaults and `httpie`-like syntax highlighting
---

To update or switch versions, run `webi curlie@stable` (or `@v1.6`, `@beta`,
etc).

## Cheat Sheet

> If you like the interface of HTTPie but miss the features of curl, curlie is
> what you are searching for. Curlie is a frontend to curl that adds the ease of
> use of httpie, without compromising on features and performance. All curl
> options are exposed with syntax sugar and output formatting inspired from
> httpie.

**Headers** (`:`) are recognized by being in the format `Key-Name:Value`.

**JSON** (`=`) is the default encoding for `key=value` pairs.

### How to alias as `curl`

Use [aliasman](/aliasman):

```sh
aliasman curl 'curlie'
alias curl='curlie'
```

This will affect the interactive shell, but not scripts.

### Simple GET

```sh
curlie -v example.com
```

### POST simple JSON with headers

```sh
curlie -v POST httpbin.org/status/201 "Authorization: Bearer xxxx" "name=John Doe"
```

### POST large JSON

```sh
curlie -v POST httpbin.org/status/201 "Authorization: Bearer xxxx" -d '
[
    {
        "name": "John Doe"
    }
]
'
```

### Spoof Host and SNI

The `--resolve` option is for when you need to test a local service as if it had
a remote hostname and TLS SNI (or when you want to break things 😈).

```sh
curlie https://foo.example.com:8443 "Host: foo.example.com" \
    --resolve foo.example.com:8443:127.0.0.1
```
