---
title: Serviceman
homepage: https://git.rootprojects.org/root/serviceman
tagline: |
  Serviceman: cross-platform service management for Linux, Mac, and Windows.
description: |
  Serviceman is a hassle-free wrapper around your system launcher. It works with the default system launcher to make it easy to start _user_- and _system_-level services, such as webservers, backup scripts, network and system tools, etc.

  Supports
    - `launchctl` (macOS)
    - `systemctl` (Linux)
    - The Registry (Windows)
---

Serviceman can run an app in just about any programming language very simply.

If you'd like to learn what `serviceman` does without actually making changes,
add the `--dryrun` option.

### Node.js

**Development Server**

```bash
pushd ./my-node-app/
sudo env PATH="$PATH" \
    serviceman add --cap-net-bind --system npx nodemon
```

**Production Server**

```bash
pushd ./my-node-app/
sudo env PATH="$PATH" \
    serviceman add --cap-net-bind --system npm start
```

### Golang

```bash
pushd ./my-go-package/
sudo env PATH="$PATH" \
    serviceman add --system go run -mod=vendor cmd/my-service/*.go --port 3000
```

```bash
pushd ./my-go-package/
go build -mod=vendor cmd/my-service
sudo env PATH="$PATH" \
    serviceman add --cap-net-bind --system ./my-service --port 80
```

### And even bash!

```bash
sudo env PATH="$PATH" serviceman add bash ./backup.sh /mnt/data
```

### Use `--dryrun` to see the generated launcher config:

```bash
sudo env PATH="$PATH" \
    serviceman add --dryrun bash ./backup.sh /mnt/data
```

### See the (sub)command help

The main help, showing all subcommands:

```bash
serviceman --help
```

Sub-command specific help:

```bash
serviceman add --help
```
