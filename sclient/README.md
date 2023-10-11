---
title: sclient
homepage: https://github.com/therootcompany/sclient
tagline: |
  sclient: a cross-platform tool to unwrap TLS as plain text.
---

To update or switch versions, run `webi sclient@stable`.

## Cheat Sheet

> sclient unwraps encrypted connections (HTTPS/TLS/SSL) so that you can work
> with them as as plain text (or binary). Great for debugging web services, and
> security research.
>
> Think of it like netcat (or socat) + openssl s_client.

You can _literally_ use this on example.com:

```sh
sclient example.com:443 localhost:3000
```

To use it with an http client, just set the Host header to the original domain:

```sh
curl -H "Host: example.com" http://localhost:3000
```

```html
<!doctype html>
<html>
  <body>
    <h1>Example Domain</h1>
    This domain is for use in illustrative examples in documents. You may use
    this domain in literature without prior coordination or asking for
    permission.
    <a href="https://www.iana.org/domains/example">More information...</a>
  </body>
</html>
```

### How to Proxy SSH over SSL

SSH can be tunneled within HTTPS, TLS, SSL, WebSockets, etc.

```sh
ssh -o ProxyCommand="sclient %h" jon.telebit.io
```

This is useful to be able to connect to SSH even from behind a corporate
packet-inspection firewall. It can also be used to multiplex and relay multiple
ssh connections through a single host.

### How to unwrap TLS for Telnet (HTTP/HTTPS)

```sh
sclient example.com:443 localhost:3000
```

```sh
telnet localhost 3000
```

### How to unwrap TLS for SMTP/SMTPS/STARTTLS

```sh
sclient smtp.gmail.com:465 localhost:2525
```

```sh
telnet localhost 2525

Trying 127.0.0.1...
Connected to localhost.
Escape character is '^]'.
220 smtp.gmail.com ESMTP c79-v6sm37968282pfb.147 - gsmtp
```

### How to use with stdin / stdout

```sh
sclient whatever.com -
```

Use just like netcat or telnet. A manual HTTP request, for example:

```text
> GET / HTTP/1.1
> Host: whatever.com
> Connection: close
>
```

### How to pipe connections

```sh
printf "GET / HTTP/1.1\r\nHost: telebit.cloud\r\n\r\n" | sclient telebit.cloud
```

### How to Spoof SNI

Sometimes you want to check to see if your site is vulnerable to SNI-spoofing
attacks, such as Domain Fronting.

The literal domains `example.net` and `example.com` are _actually_ vulnerable to
SNI spoofing:

```sh
sclient --servername example.net example.com:443 localhost:3000
curl -H "example.com" http://localhost:3000
```

Most domains, however, are not:

```sh
sclient --servername google.net google.com:443 localhost:3000
curl -H "google.com" http://localhost:3000
```
