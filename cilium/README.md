---
title: cilium
homepage: https://github.com/cilium/cilium-cli
tagline: |
  cilium: manage & troubleshoot Kubernetes clusters running Cilium
---

To update or switch versions, run `webi cilium@stable` (or `@v2`, `@beta`,etc).

### Files

These are the files / directories that are created and/or modified with this
install:

```text
~/.config/envman/PATH.env
~/.local/bin/cilium
~/.local/opt/cilium/
```

## Cheat Sheet

> Cilium is an open source, cloud native solution for providing, securing, and
> observing network connectivity between workloads, fueled by the revolutionary
> Kernel technology eBPF.

Quick Start User Guide:

<https://docs.cilium.io/en/stable/gettingstarted/k8s-install-default/#k8s-install-quick>

To install the default version of the Cilium image:

```sh
cilium install
```

To upgrade to a specific version of the Cilium image:

```sh
cilium upgrade --version v1.15.3
```

To check the status of the current Cilium deployment:

```sh
cilium status
```
