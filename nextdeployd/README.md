---
title: NextDeploy Daemon
homepage: https://github.com/aynaash/nextdeploy
tagline: |
  Server-side orchestration daemon for NextDeploy
description: |
  The NextDeploy daemon runs on your VPS to handle container orchestration, health monitoring, and deployment automation. Works with the NextDeploy CLI for seamless Next.js deployments.
---

## Cheat Sheet

> The NextDeploy daemon provides PM2-like process management for your Next.js containers with automatic health checks, restarts, and monitoring.

### Installation (Linux Only)

```sh
curl https://webi.sh/nextdeployd | sh
```

### Start the Daemon

```sh
# Using systemd (recommended)
sudo systemctl enable nextdeployd
sudo systemctl start nextdeployd

# Check status
sudo systemctl status nextdeployd
```

### Daemon Commands

The daemon responds to CLI commands sent via the NextDeploy CLI:

```sh
# Pull and deploy a container
nextdeployd pull --image=myapp:latest

# Switch containers (blue-green deployment)
nextdeployd switch --current=myapp:v1 --new=myapp:v2

# Setup Caddy reverse proxy
nextdeployd caddy --setup

# View logs
journalctl -u nextdeployd -f
```

### Configuration

The daemon reads from `/etc/nextdeploy/daemon.yml`:

```yaml
socket_path: /var/run/nextdeploy.sock
log_dir: /var/log/nextdeploy
docker_socket: /var/run/docker.sock
```

### Features

- **🔄 Auto-restart** - PM2-like container monitoring
- **💚 Health checks** - Automatic failure detection
- **📊 Metrics** - CPU, memory, disk monitoring
- **🔐 Secure** - Unix socket + JWT authentication
- **🚀 Blue-green** - Zero-downtime deployments

### Files

These are the files / directories that are created and/or modified with this install:

```text
~/.local/bin/nextdeployd
~/.local/opt/nextdeployd/
/etc/systemd/system/nextdeployd.service (if using systemd)
/var/log/nextdeploy/ (logs)
```

### Requirements

- **Linux only** (systemd recommended)
- Docker installed and running
- Port 80/443 available (for Caddy)

### Security

The daemon uses:
- Unix sockets for local communication
- JWT tokens for authentication
- ECDH key exchange for secrets
- Ed25519 signatures for audit logs
