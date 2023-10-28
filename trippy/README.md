---
title: Trippy
homepage: https://github.com/fujiapple852/trippy
tagline: |
  Trippy: A tool that combines the functionality of traceroute and ping designed for networking issue analysis.
---

To update or switch versions, run `webi trip@stable` (or `@v0.8`, `@beta`, etc).

## Cheat Sheet

> Trippy combines the functionality of `traceroute` and `ping` to assist in
> analyzing networking issues. It supports multiple protocols such as ICMP, UDP,
> and TCP, and is equipped with a Tui interface for detailed analysis.

```sh
sudo env PATH="$PATH" trip example.com
```

![](https://github.com/fujiapple852/trippy/blob/0.8.0/assets/0.8.0/hop_details.png?raw=true)

## Table of Contents

- Files
- Granting Root
- Tracing Protocols
- Tracing Options
- GoeIP Map

### Files

These are the files / directories that are created and/or modified with this
install:

```text
~/.config/trippy.toml
~/.local/bin/trip
<PROJECT-DIR>/.trippy.toml

# Windows
~/.local/bin/sudo.cmd
/Windows/System32/vcruntime140.dll (msvc runtime)
```

### How to Always Run as Root

Due to the nature of raw network access, `trip` always needs to run with
elevated network privileges.

On Linux `setcap` can be used to limit its root privileges to the network only.
On other systems it may need full root access.

**Linux**

```sh
trip_bin="$( readlink -f "$( command -v trip )" )"

sudo setcap 'CAP_NET_RAW+p' "${trip_bin}"
```

**macOS**

```sh
trip_bin="$( command -v trip )"

sudo chown root "${trip_bin}" && \
    sudo chmod +s "${trip_bin}"
```

**Windows**

1. You need to add a firewall rule to allow ICMP
   ```pwsh
   New-NetFirewallRule -DisplayName "ICMP Trippy Allow" -Name ICMP_TRIPPY_ALLOW -Protocol ICMPv4 -Action Allow
   ```
2. You'll need to run with an Administrator shell, or `sudo.cmd` **every time**:
   ```sh
   sudo.cmd trip.exe example.com
   ```

### How to Trace with Various Protocols

You can use `icmp`, `tcp`, or `udp`:

```sh
trip --protocol icmp example.com
```

### How to set Tracing Options

You can pick a payload byte pattern (0-255) and packet size:

```sh
trip --packet-size 64 --payload-pattern 255
```

### How to View GeoIP Mapping

You'll need to download a geoip map database, such as this:

- <https://dev.maxmind.com/geoip/geolite2-free-geolocation-data>

```sh
trip example.com --geoip-mmdb-file ./GeoLite2-City.mmdb --tui-geoip-mode long
```

![](https://github.com/fujiapple852/trippy/raw/0.8.0/assets/0.8.0/world_map.png)
