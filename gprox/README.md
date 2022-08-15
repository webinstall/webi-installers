---
title: gprox
homepage: https://github.com/creedasaurus/gprox
tagline: |
  gprox: a simple local ssl proxy for development
---

### Updating `gprox`

`webi gprox`

## Cheat Sheet

`gprox` was built to be a no-dependency development tool for simply proxying
HTTPS traffic to a local HTTP endpoint. It was written as a port of
[local-ssl-proxy](https://github.com/cameronhunter/local-ssl-proxy), a perfectly
good NodeJS app for the same purpose. But the benefit is that you can install
`gprox` very simply from `webi` or `go` (if you must), and you dont have to
worry at all about NodeJS versions, etc! Plus there isn't any elevated access
given to an interpreter you dont know much about if you're using `webi`.

The fastest way to get started is just by running:

```sh
gprox
# example output
# 9:12PM INF Running proxy! from=https://localhost:9001 to=http://localhost:9000
```

And you're off to the races!

That is... if you're app happens to be running on port `9000`. If not, no
worries! Simply pass the target port option `-t, --target` and specify the port
your app _is_ running on.

```sh
gprox -t 8080
```

Feeling like you should save this magic built-in cert so you can inspect it for
anything?

```sh
gprox --dropcert
```

Want to use your own cert/key?

```sh
gprox -c testcert.crt -k testkey.key
```

And for anything else, just use the `-h, --help` flag to get a little more
information or refer to the
[README](https://github.com/creedasaurus/gprox/blob/main/README.md):

```
❯ gprox --help
Usage:
  gprox [OPTIONS]

Application Options:
  -n, --hostname=  The hostname to be used for the local proxy (default: localhost)
  -s, --source=    The source port that you will hit to go through the proxy (default: 9001)
  -t, --target=    The port you are targeting (default: 9000)
  -c, --cert=      Path to a .cert file
  -k, --key=       Path to a .key file
  -o, --config=
  -d, --dropcerts  Save the built-in cert/key files to disk
      --version

Help Options:
  -h, --help       Show this help message
```
