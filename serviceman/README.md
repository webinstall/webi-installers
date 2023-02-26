---
title: Serviceman
homepage: https://git.rootprojects.org/root/serviceman
tagline: |
  Serviceman: cross-platform service management for Linux, Mac, and Windows.
---

To update or switch versions, run `webi serviceman@stable`

## Cheat Sheet

> Serviceman is a hassle-free wrapper around your system launcher. It works with
> the default system launcher to make it easy to start _user_- and
> _system_-level services, such as webservers, backup scripts, network and
> system tools, etc.

Supports

- `launchctl` (macOS)
- `systemctl` (Linux)
- The Registry (Windows)

Serviceman can run an app in just about any programming language very simply.

If you'd like to learn what `serviceman` does without actually making changes,
add the `--dryrun` option.

### Example: Bash

```sh
sudo env PATH="$PATH" serviceman add bash ./backup.sh /mnt/data
```

### Example: Node.js

**Development Server**

```sh
pushd ./my-node-app/

sudo env PATH="$PATH" \
    serviceman add --system --cap-net-bind \
    npx nodemon ./server.js
```

**Production Server**

```sh
pushd ./my-node-app/

sudo env PATH="$PATH" \
    serviceman add --system --cap-net-bind \
    npm start
```

### Example: Golang

```sh
pushd ./my-go-package/

sudo env PATH="$PATH" \
    serviceman add --system \
    go run -mod=vendor cmd/my-service/*.go --port 3000
```

```sh
pushd ./my-go-package/
go build -mod=vendor cmd/my-service

sudo env PATH="$PATH" \
    serviceman add --cap-net-bind --system \
    ./my-service --port 80
```

### How to see all services

```sh
serviceman list --system
serviceman list --user
```

```text
serviceman-managed services:

        example-service
```

### How to restart a service

You can either `add` the service again (which will update any changed options),
or you can `stop` and then `start` any service by its name:

```sh
sudo env PATH="$PATH" serviceman stop example-service
sudo env PATH="$PATH" serviceman start example-service
```

## What a typical systemd .service file looks like

```text
[Unit]
Description=example-service
After=network-online.target
Wants=network-online.target systemd-networkd-wait-online.service

[Service]
Restart=always
StartLimitInterval=10
StartLimitBurst=3

User=root
Group=root

WorkingDirectory=/srv/example-service
ExecStart=/srv/example-service/bin/example-command start
ExecReload=/bin/kill -USR1 $MAINPID

# Allow the program to bind on privileged ports, such as 80 and 443
CapabilityBoundingSet=CAP_NET_BIND_SERVICE
AmbientCapabilities=CAP_NET_BIND_SERVICE
NoNewPrivileges=true

[Install]
WantedBy=multi-user.target
```

## What a typical launchd .plist file looks like

```text
<?xml version="1.0" encoding="UTF-8"?>
<!-- Generated for serviceman. Edit as you wish, but leave this line. -->
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>Label</key>
  <string>example-service</string>
  <key>ProgramArguments</key>
  <array>
    <string>/Users/me/example-service/bin/example-command</string>
    <string>start</string>
  </array>

  <key>RunAtLoad</key>
  <true/>
  <key>KeepAlive</key>
  <true/>

  <key>WorkingDirectory</key>
  <string>/Users/me/example-service</string>

  <key>StandardErrorPath</key>
  <string>/Users/me/.local/share/example-service/var/log/example-service.log</string>
  <key>StandardOutPath</key>
  <string>/Users/me/.local/share/example-service/var/log/example-service.log</string>
</dict>
</plist>
```

### Use `--dryrun` to see the generated launcher config:

```sh
sudo env PATH="$PATH" \
    serviceman add --system --dryrun \
    bash ./backup.sh /mnt/data
```

### See the (sub)command help

The main help, showing all subcommands:

```sh
serviceman --help
```

Sub-command specific help:

```sh
serviceman add --help
```
