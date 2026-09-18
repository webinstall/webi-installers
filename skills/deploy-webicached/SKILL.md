---
name: deploy-webicached
description: Deploy webicached binary to beta.webi.sh or webi.sh. Use when building, uploading, or restarting the cache daemon. Covers cross-compile, conf sync, service management.
---

## One-step deploy

For production, update the server checkout first. Leave it on its current
`main` or `hotfix` branch and rebase it on `origin/main`:

```sh
ssh webi.sh <<'SSH_EOF'
set -Cue
cd ~/srv/webinstall.dev/installers
git pull --rebase origin main
SSH_EOF
```

Then run the deploy from a clean local worktree at the same `origin/main`
commit:

```sh
./scripts/deploy-webicached.sh webi.sh
```

The deploy script syncs `releases.conf` files. Package pages also need the
package directory (`README.md`, `install.sh`, and `install.ps1`) present in the
production checkout; `git pull` supplies those tracked files. Afterward, refresh
a package's release cache explicitly:

```sh
ssh webi.sh <<'SSH_EOF'
set -Cue
. ~/.config/envman/PATH.sh
webicached \
  --envfile ~/srv/webinstall.dev/.env.secret \
  --conf ~/srv/webinstall.dev/installers/ \
  --raw ~/.cache/webi/raw \
  --once '<pkgname>'
SSH_EOF
```

For beta, use `./scripts/deploy-webicached.sh beta.webi.sh`.

Builds with version ldflags, stops service, uploads, syncs conf, starts, verifies.

## Manual steps (if needed)

### Build

```sh
VERSION="$(git describe --tags --always)"
COMMIT="$(git rev-parse --short HEAD)"
DATE="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
GOOS=linux GOARCH=amd64 GOAMD64=v2 go build \
  -ldflags "-X main.version=${VERSION} -X main.commit=${COMMIT} -X main.date=${DATE}" \
  -o agents/tmp/webicached ./cmd/webicached
```

MUST: Build from the `ref-webi-go` worktree (or branch containing `cmd/webicached`).

### Deploy

```sh
ssh beta.webi.sh "serviceman stop webicached"
scp agents/tmp/webicached beta.webi.sh:~/bin/webicached
```

MUST: Stop service before scp — Linux refuses to overwrite a running binary.

### Sync releases.conf

```sh
rsync -av --include='*/' --include='releases.conf' --exclude='*' \
  ./ beta.webi.sh:~/srv/beta.webinstall.dev/installers/
```

MUST: Run from the worktree root. The server has no checkout of this branch — conf files must be synced explicitly.

### Start

```sh
ssh beta.webi.sh "serviceman start webicached"
```

### Verify

```sh
ssh beta.webi.sh "sleep 5 && serviceman logs webicached"
```

Expected: "batch: N stale, refreshing 20" or "all packages fresh, sleeping 9s"

## Smoke test

```sh
ssh beta.webi.sh "curl -sSf http://localhost:3080/api/releases/bat.json | head -c 100"
ssh beta.webi.sh "curl -sSf -A 'curl/7.81.0 Linux x86_64' http://localhost:3080/api/installers/bat.sh | head -3"
```

Expected: JSON array with release objects; shell script with `PKG_NAME='bat'`.

## Service management

Load the webi-managed `PATH` before registering the service so `serviceman`
writes its resolved path into the service definition:

```sh
. ~/.config/envman/PATH.env
serviceman add --name webicached \
  --workdir ~/srv/beta.webinstall.dev/installers/ -- \
  webicached \
    --env-file ~/srv/beta.webinstall.dev/.env.secret \
    --conf ~/srv/beta.webinstall.dev/installers/ \
    --raw ~/.cache/webi/raw \
    --interval 30s
```

```sh
serviceman status webicached
serviceman restart webicached
serviceman logs webicached
```

## Server layout

| Path | Purpose |
|------|---------|
| `~/bin/webicached` | Binary |
| `~/srv/beta.webinstall.dev/installers/` | Conf dir (releases.conf files) |
| `~/.cache/webi/legacy/` | Cache output (fsstore, legacy JSON format) |
| `~/.cache/webi/raw/` | Raw upstream API responses |
| `~/srv/beta.webinstall.dev/.env.secret` | GITHUB_TOKEN |
| `/etc/systemd/system/webicached.service` | Service unit (created by serviceman) |

## Flags reference

| Flag | Default | Purpose |
|------|---------|---------|
| `--conf` | `.` | Dir with `{pkg}/releases.conf` files |
| `--legacy` | `~/.cache/webi/legacy` | Legacy cache output directory |
| `--raw` | `~/.cache/webi/raw` | Raw upstream response cache |
| `--token` | `$GITHUB_TOKEN` | GitHub API token |
| `--interval` | `9s` | Delay between package fetches in a batch |
| `--once` | false | Run once then exit |
| `--eager` | false | Fetch all on startup (not staleness-based) |
| `--shallow` | false | Only first page of releases |
| `--no-fetch` | false | Classify from rawcache only |
| `--page-delay` | `2s` | Delay between paginated API pages |

## One-shot refresh (specific packages)

```sh
ssh beta.webi.sh ". ~/srv/beta.webinstall.dev/.env.secret && ~/bin/webicached \
  --conf ~/srv/beta.webinstall.dev/installers/ \
  --raw ~/.cache/webi/raw \
  --once '<pkgname>'"
```
