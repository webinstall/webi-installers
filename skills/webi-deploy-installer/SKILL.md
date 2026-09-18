---
name: webi-deploy-installer
description: Deploy Webi installers and `webicached` classifier changes on beta.webi.sh and webi.sh.
---

# Deploy Webi installer changes

Use `../webi-installers.d/` for a clean worktree at the commit being tested.
Keep the primary worktree and unrelated changes untouched.

## One package

Use this for changes limited to one package's installer or `releases.conf`.
The script takes a host followed by one or more package names.

```sh
./scripts/deploy-installers.sh beta.webi.sh timeout xz
```

It syncs each package's installer files, refreshes only that package's release
cache, and checks the public installer endpoint. Package arguments matter:
without them, `webicached` refreshes the whole catalog and spends the GitHub API
budget.

Test the result:

```sh
curl -fsSL "https://beta.webi.sh/${g_pkg}" | sh
```

Check the installed command and version.

## Endpoints

| Endpoint | Purpose |
| --- | --- |
| `https://beta.webi.sh/<pkg>` | bootstrap installer |
| `https://beta.webi.sh/api/installers/<pkg>@<ver>.sh?formats=zip,tar` | generated install script |
| `https://beta.webi.sh/api/releases/<pkg>@<ver>.json` | release assets (JSON) |
| `https://beta.webi.sh/api/releases/<pkg>@<ver>.tab` | release assets (TSV) |
| `https://webi.sh/<pkg>` | production bootstrap |
| `https://webinstall.dev/api/installers/<pkg>@<ver>.sh?formats=zip,tar` | production install script |
| `https://webinstall.dev/api/releases/<pkg>@<ver>.json` | production assets (JSON) |
| `https://webinstall.dev/api/releases/<pkg>@<ver>.tab` | production assets (TSV) |

## Classifier or multiple packages

A package-only refresh does not deploy Go changes in
`internal/classifypkg/`, `internal/classify/`, or
`internal/releases/<pkg>/variants.go`. Use the repository deploy script:

```sh
./scripts/deploy-webicached.sh beta.webi.sh
```

It builds and restarts `webicached`, syncs all `releases.conf` files, and checks
the deployed version and logs. Deploy production only after beta succeeds:

```sh
./scripts/deploy-webicached.sh webi.sh
```

For classifier changes, inspect the raw cache on the target host. This avoids
confusing the classifier result with a transformed public API response:

```sh
g_pkg=bat
ssh beta.webi.sh <<SSH_EOF
set -Cue
jq -r '[.[] | select(.os == "linux") | .libc] | unique' \
  ~/.cache/webi/legacy/${g_pkg}.json
SSH_EOF
```
