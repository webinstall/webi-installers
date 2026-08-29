---
title: Realmroot Toolbox
homepage: https://realmroot.dev
tagline: |
  Realmroot is an Agent-native toolbox for approved access to private resources.
---

To update to the latest stable release, run `webi realmroot@stable`. To install
an explicit release, run `webi realmroot@0.4.2` with the required version.

### Files

These files are created or modified by this installer:

```text
~/.config/envman/PATH.env
~/.local/bin/realmroot
~/.local/opt/realmroot-vVERSION/bin/realmroot
```

## Cheat Sheet

> Realmroot gives Agents one stable identity and lets them discover and invoke
> private capabilities with controller-approved authority.

### Inspect the Agent identity

```sh
realmroot agent whoami
```

### Discover available Resource Servers

```sh
realmroot toolbox
realmroot toolbox github
```

### Request task-scoped authority

```sh
realmroot agent request \
  --resource-server github \
  --context realmroot \
  --scope contents:read
```

### Run an authenticated native command

```sh
realmroot exec github -- gh repo view realmroot/cli
```

### Inspect the installed version

```sh
realmroot version
```
