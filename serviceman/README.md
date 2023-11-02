---
title: Serviceman
homepage: https://git.rootprojects.org/root/serviceman
tagline: |
  Serviceman generates and enables startup files on Linux, Mac, and Windows.
---

To update or switch versions, run `webi serviceman@stable` (or `@v0.8`, `beta`,
etc).

## Cheat Sheet

> A **lightweight, cross-platform wrapper** to more easily \
> use your **native init system** to control system **service daemons** \
> and user **launch agents**. \
>
> Works for web servers, backup scripts, network and system tools, etc, in all
> languages.

- Launchd (macOS)
- Systemd (Linux)
- OpenRC (Alpine, Docker)
- Windows: Startup Registry

Works for _any program_, written in _any language_.

## Table of Contents

- Files
- User Agents & System Daemons
  - Bash, Node, Go, etc
- Service Management
- Dry Run
- Unit File Examples
  - systemd, launchd, openrc

### Files

These are the files / directories that are created and/or modified with this
install:

```text
~/.config/envman/PATH.env
~/.local/bin/serviceman
```

This will also generate init system unit files according to your OS:

(use the `--dryrun` option to learn what `serviceman` does without making any
changes)

- `launchctl` (macOS)
  ```sh
  ~/Library/LaunchAgents/<AGENT>.plist
  /Library/LaunchDaemons/<DAEMON>.plist
  ```
- `systemctl` (Linux)
  ```sh
  /etc/systemd/system/<DAEMON>.service
  ~/.config/systemd/user/<AGENT>.service
  ```
- `openrc` (Alpine, Docker)
  ```text
  /etc/init.d/<DAEMON>
  ```
- The Registry (Windows)
  ```text
  HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Run <AGENT>
  ```

### Example: Bash

```sh
sudo env PATH="$PATH" \
    serviceman add --system --path="$PATH" -- \
    bash ./backup.sh /mnt/data
```

### Example: Node.js

**Development Server**

```sh
pushd ./my-node-app/

sudo env PATH="$PATH" \
    serviceman add --system --path="$PATH" \
    --cap-net-bind -- \
    npx nodemon ./server.js
```

**Production Server**

```sh
pushd ./my-node-app/

sudo env PATH="$PATH" \
    serviceman add --system --path="$PATH" \
    --cap-net-bind -- \
    npm start
```

### Example: Golang

```sh
pushd ./my-go-package/

sudo env PATH="$PATH" \
    serviceman add --system --path="$PATH" \
    -- \
    go run -mod=vendor cmd/my-service/*.go --port 3000
```

```sh
pushd ./my-go-package/
go build -mod=vendor cmd/my-service

sudo env PATH="$PATH" \
    serviceman add --system --path="$PATH" \
    --cap-net-bind -- \
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

### See the (sub)command help

The main help, showing all subcommands:

```sh
serviceman --help
```

Sub-command specific help:

```sh
serviceman add --help
```

### Use `--dryrun` to see the generated launcher config:

```sh
sudo env PATH="$PATH" \
    serviceman add --system --path="$PATH" \
    --dryrun -- \
    bash ./backup.sh /mnt/data
```

### What a typical systemd .service file looks like

`systemd` is the init system on cloud-init enabled server distros, and most
desktop distros.

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

### What a typical `init.d` service script looks like

`openrc` is the `init` system on Alpine and other Docker and
_container-friendly_ Linuxes.

`/etc/init.d/exampled`:

```sh
#!/sbin/openrc-run
supervisor=supervise-daemon

name="Example System Daemon"
description="A Service for Logging 'Hello, World', a lot!"
description_checkconfig="Check configuration"
description_reload="Reload configuration without downtime"

# example:
# exampled run --port 1337 --envfile /path/to/env
# exampled check-config --port 1337 --envfile /path/to/env
# exampled reload --port 1337 --envfile /path/to/env

# for setting Config
: ${exampled_opts:="--envfile /root/.config/exampled/env"}

command=/root/bin/exampled
command_args="run --port 1337 $exampled_opts"
command_user=root:root
extra_commands="checkconfig"
extra_started_commands="reload"
output_log=/var/log/exampled.log
error_log=/var/log/exampled.err

depend() {
    need net localmount
    after firewall
}

checkconfig() {
    ebegin "Checking configuration for $name"
    su ${command_user%:*} -s /bin/sh -c "$command check-config $exampled_opts"
    eend $?
}

reload() {
    ebegin "Reloading $name"
    su ${command_user%:*} -s /bin/sh -c "$command reload $exampled_opts"
    eend $?
}

stop_pre() {
    if [ "$RC_CMD" = restart ]; then
        checkconfig || return $?
    fi
}
```

### What a typical launchd .plist file looks like

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
