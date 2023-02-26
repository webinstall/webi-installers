---
title: My IP
homepage: https://webinstall.dev/myip
tagline: |
  My IP answers the question "what's my IP address?"
---

## Updating `myip`

```sh
webi myip
```

## Cheat Sheet

`myip` will contact ipify.org to tell you your IP addresses:

1. `api.ipify.org` for your IPv4 or A address
2. `api6.ipify.org` for your IPv6 or AAAA address

Example output:

```text
IPv4 (A)   : 136.36.196.101
IPv6 (AAAA): 2605:a601:a919:9800:f8be:f2c4:9ad7:9763
```

### What is an IP address?

An IP or Internet Protocol address is basically the phone number of your
computer or server.

Whenever you visit a domain - such as https://google.com - the `google.com` part
is _resolved_ to the IP address using, quite literally, the internet's Contacts
list, known as DNS.

### How to get your IP address?

Due to how complex networking can be, the most reliable way to get your IP
address is basically to "make a call" to another server and ask it to tell you
what shows up on the "called id", as it were.

_IPify_ is such a service.

You likely have an IPv4 or A address as well as an IPv6 or AAAA address.

To find out your IPv4 or A address:

```sh
curl -s https://api.ipify.org
```

To find out your IPv6 or AAAA address:

```sh
curl -s https://api6.ipify.org
```

To find out either address:

```sh
curl -s https://api46.ipify.org
```

You can also use the `ifconfig`, `ip`, or `ipconfig` commands to figure this
out, but they may give you incorrect information if the network setup is complex
(as is the case... most of the time - home and business networks, cloud
networks, etc).
