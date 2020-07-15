---
title: curlie
homepage: https://github.com/rs/curlie
tagline: |
  curlie wraps `curl` with modern defaults and `httpie`-like syntax highlighting
---

## Updating

```bash
webi curlie@stable
```

Use the `@beta` tag for pre-releases.

## Cheat Sheet

> If you like the interface of HTTPie but miss the features of curl, curlie is
> what you are searching for. Curlie is a frontend to curl that adds the ease of
> use of httpie, without compromising on features and performance. All curl
> options are exposed with syntax sugar and output formatting inspired from
> httpie.

**Headers** (`:`) are recognized by being in the format `Key-Name:Value`.

**JSON** (`=`) is the default encoding for `key=value` pairs.

### Simple GET

```bash
curlie -v example.com
```

### POST simple JSON with headers

```bash
curlie -v POST httpbin.org/status/201 "Authorization: Bearer xxxx" "name=John Doe"
```

### POST large JSON

```bash
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

```bash
curlie https://foo.example.com:8443 "Host: foo.example.com" \
    --resolve foo.example.com:8443:localhost
```
