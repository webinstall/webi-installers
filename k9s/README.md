---
title: K9s
homepage: https://github.com/derailed/k9s
tagline: |
  K9s provides a terminal UI to interact with your Kubernetes clusters
---

To update or switch versions, run `webi k9s@stable` (or `@v0.24`, `@beta`, etc).

## Cheat Sheet

The information in this section is a copy of the preflight requirements and
common command line arguments from k9s (https://github.com/derailed/k9s).

> `k9s` aim is to make it easier to navigate, observe and manage your
> applications in the wild. K9s continually watches Kubernetes for changes and
> offers subsequent commands to interact with your observed resources.

### Preflight check

K9s uses 256 colors terminal mode. On `Nix system make sure TERM is set
accordingly.

```sh
export TERM=xterm-256color
```

To run k9s:

```sh
k9s
```

### Command line arguments

List all available CLI options

```sh
k9s help
```

To get info about K9s runtime (logs, configs, etc..)

```sh
k9s info
```

To run K9s in a given namespace

```sh
k9s -n mycoolns
```

Start K9s in an existing KubeConfig context

```sh
k9s --context coolCtx
```

Start K9s in readonly mode - with all cluster modification commands disabled

```sh
k9s --readonly
```
