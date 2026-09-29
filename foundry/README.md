---
title: foundry
homepage: https://github.com/catalystcommunity/foundry
tagline: |
  foundry: Manage Catalyst Community K3s/Kubernetes stacks (not the Ethereum toolchain).
description:
  A CLI that builds and operates a Catalyst Community tech stack. Use it to
  register hosts, install a K3s cluster and its components (OpenBAO, DNS, Zot,
  storage), and check status, logs, and backups.
---

To update or switch versions, run `webi foundry@stable` (or `@v0.7.5`, `@beta`,
etc).

### Files

These are the files that are created and/or modified with this installer:

```text
~/.config/envman/PATH.env
~/.local/bin/foundry
~/.local/opt/foundry-VERSION/bin/foundry
```

## Cheat Sheet

> `foundry` builds and runs a Catalyst Community stack. It manages hosts, a K3s
> cluster, and infrastructure components (OpenBAO, DNS, Zot, storage,
> monitoring) from one CLI.

### How to create a config file

Run `config init` to make a new config file. Give it a cluster name and a
domain:

```sh
foundry config init \
  --name my-cluster \
  --cluster-name my-cluster \
  --primary-domain catalyst.local
```

Answer the prompts to set the network values. Or add `--non-interactive` to get
a template with placeholders:

```sh
foundry config init --non-interactive
```

List your config files, and show the active one with secrets hidden:

```sh
foundry config list
foundry config show
```

Point foundry at a specific config file with `--config`, or set
`FOUNDRY_CONFIG`:

```sh
export FOUNDRY_CONFIG=~/.foundry/my-cluster.yaml
```

### How to add a host

Add each machine that will join the stack. Give it an address, an SSH user, and
one or more roles:

```sh
foundry host add vm1 \
  --address 10.16.0.42 \
  --user root \
  --roles cluster-control-plane
```

List the hosts you have registered:

```sh
foundry host list
```

### How to install the stack

Run `stack install` after your config and hosts are set:

```sh
foundry stack install
```

This command sets up the hosts, plans the network, and installs OpenBAO,
PowerDNS, Zot, and K3s in order. Run it again after an interruption. It picks up
where it stopped.

Skip the prompts in a script with `--non-interactive` and `--yes`:

```sh
foundry stack install --non-interactive --yes
```

Preview the plan first. Add `--dry-run`. It changes nothing:

```sh
foundry stack install --dry-run
```

### How to check stack and component status

Check the whole stack in one command:

```sh
foundry stack status
```

List the components foundry knows how to install, and check one component on its
own:

```sh
foundry component list
foundry component status openbao
```

Install one extra component, such as a storage backend, after the base stack is
up:

```sh
foundry component install storage --backend local-path
```

### How to view logs

View the logs for one pod:

```sh
foundry logs grafana-0
```

Add `-n` for a namespace, `-f` to follow the stream, and `--tail` to limit the
lines:

```sh
foundry logs grafana-0 -n monitoring -f --tail 100
```

Select pods by label instead of by name:

```sh
foundry logs -l app=grafana
```

For older log history, use Grafana Explore with Loki instead of `foundry logs`.

### How to back up the cluster

Create a backup with Velero. Give it a name, or let foundry generate one from
the timestamp:

```sh
foundry backup create my-backup
```

Keep the backup for 30 days, and wait for it to finish:

```sh
foundry backup create my-backup --ttl 720h --wait
```

List your backups, and restore from one:

```sh
foundry backup list
foundry backup restore my-backup
```
