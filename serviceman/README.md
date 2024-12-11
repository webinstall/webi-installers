---
title: Serviceman
homepage: https://github.com/bnnanet/serviceman
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
serviceman add --name 'backup' -- \
    bash ./backup.sh /mnt/data
```

### Example: Node.js

**Development Server**

```sh
pushd ./my-node-app/

serviceman add --name 'my-node-app' -- \
    npx nodemon ./server.js
```

**Production Server**

```sh
pushd ./my-node-app/

serviceman add --name 'my-node-app' -- \
    npm start
```

### Example: Golang

```sh
pushd ./my-go-package/

serviceman add --name 'my-service' -- \
    go run -mod=vendor cmd/my-service/*.go --port 3000
```

```sh
pushd ./my-go-package/
go build -mod=vendor cmd/my-service

serviceman add --name 'my-service' -- \
    ./my-service --port 80
```

### How to see all services

```sh
serviceman list --system --all
serviceman list --agent --all
```

```text
serviceman-managed services:

        example-service
```

### How to restart a service

You can either `add` the service again (which will update any changed options),
or you can `stop` and then `start` any service by its name:

```sh
serviceman stop 'example-service'
serviceman start 'example-service'
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
serviceman add --name 'my-backups' --dryrun -- \
    bash ./backup.sh /mnt/data
```

### What a typical systemd .service file looks like

`systemd` is the init system on cloud-init enabled server distros, and most
desktop distros.

```text
# Generated for serviceman. Edit as needed. Keep this line for 'serviceman list'.
# https://www.freedesktop.org/software/systemd/man/latest/systemd.service.html

[Unit]
Description=postgres postgres daemon
Documentation=(none)
After=network-online.target
Wants=network-online.target systemd-networkd-wait-online.service

[Service]
Restart=always
RestartSec=3
RestartSteps=5
RestartMaxDelaySec=300

User=app
Group=app

Environment="PATH=/Users/app/.local/opt/pg-essentials/bin:/home/app/.local/opt/postgres/bin:/usr/bin:/bin"
WorkingDirectory=/home/app/.local/share/postgres/var
ExecStart="/home/app/.local/opt/postgres/bin/postgres" "-D" "/home/app/.local/share/postgres/var" "-p" "5432"
ExecReload=/bin/kill -USR1 $MAINPID

# Limit the number of file descriptors and processes; see `man systemd.exec` for more limit settings.
# These are reasonable defaults for a production system.
# Note: systemd "user units" do not support this
LimitNOFILE=1048576
LimitNPROC=65536

# Enable if desired for extra file system security
# (ex: non-containers, multi-user systems)
#
# Use private /tmp and /var/tmp, which are discarded after the service stops.
; PrivateTmp=true
# Use a minimal /dev
; PrivateDevices=true
# Hide /home, /root, and /run/user. Nobody will steal your SSH-keys.
; ProtectHome=true
# Make /usr, /boot, /etc and possibly some more folders read-only.
; ProtectSystem=full
# ... except /opt/{{ .Name }} because we want a place for the database
# and /var/log/{{ .Name }} because we want a place where logs can go.
# This merely retains r/w access rights, it does not add any new.
# Must still be writable on the host!
; ReadWriteDirectories=/opt/postgres /var/log/postgres

# Grant restricted, root-like privileges to the service.
# CAP_NET_BIND_SERVICE allows binding on privileged ports as a non-root user
# CAP_LEASE allows locking files and is sometimes used for handling file uploads
# Some services may require additional capabilities:
# https://man7.org/linux/man-pages/man7/capabilities.7.html
CapabilityBoundingSet=CAP_NET_BIND_SERVICE CAP_LEASE
AmbientCapabilities=CAP_NET_BIND_SERVICE CAP_LEASE
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

# Generated for serviceman. Edit as needed. Keep this line for 'serviceman list'.
name="postgres"
# docs: (none)
description="postgres daemon"

supervisor="supervise-daemon"
output_log="/var/log/postgres"
error_log="/var/log/postgres"

depend() {
    need net
}

start_pre() {
    checkpath --directory --owner root /var/log/
    checkpath --file --owner 'app:app' ${output_log} ${error_log}
}

start() {
    ebegin "Starting ${name}"
    supervise-daemon ${name} --start \
        --chdir '/home/app/.local/share/postgres/var' \
        --env 'PATH=/Users/app/.local/opt/pg-essentials/bin:/home/app/.local/opt/postgres/bin:/usr/bin:/bin' \
        --user 'app' \
        --group 'app' \
        --stdout ${output_log} \
        --stderr ${error_log} \
        --pidfile /run/${RC_SVCNAME}.pid \
        --respawn-delay 5 \
        --respawn-max 51840 \
        --capabilities=CAP_NET_BIND_SERVICE \
        -- \
        '/home/app/.local/opt/postgres/bin/postgres' '-D' '/home/app/.local/share/postgres/var' '-p' '5432'
    eend $?
}

stop() {
    ebegin "Stopping ${name}"
    supervise-daemon ${name} --stop \
        --pidfile /run/${RC_SVCNAME}.pid
    eend $?
}
```

### What a typical launchd .plist file looks like

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!-- Generated for serviceman. Edit as needed. Keep this line for 'serviceman list'. -->
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>postgres</string>
    <key>ProgramArguments</key>
    <array>
        <string>/Users/app/.local/opt/postgres/bin/postgres</string>
        <string>-D</string>
        <string>/Users/app/.local/share/postgres/var</string>
        <string>-p</string>
        <string>5432</string>
    </array>

    <key>EnvironmentVariables</key>
    <dict>
        <key>PATH</key>
        <string>/Users/app/.local/opt/pg-essentials/bin:/Users/app/.local/opt/postgres/bin:/usr/bin:/bin</string>
    </dict>

    <key>RunAtLoad</key>
    <true/>
    <key>KeepAlive</key>
    <true/>

    <key>WorkingDirectory</key>
    <string>/Users/app/.local/share/postgres/var</string>

    <key>StandardOutPath</key>
    <string>/Users/app/.local/share/postgres/var/log/postgres.log</string>
    <key>StandardErrorPath</key>
    <string>/Users/app/.local/share/postgres/var/log/postgres.log</string>
</dict>
</plist>
```
