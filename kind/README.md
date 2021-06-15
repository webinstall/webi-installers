---
title: kind
homepage: https://github.com/kubernetes-sigs/kind
tagline: |
  kind: tool for running local Kubernetes clusters using Docker container "nodes".
---

To update or switch versions, run `webi kind@stable` (or `@v2`, `@beta`,etc).

## Cheat Sheet

> Kind uses a single docker container to run a lightweight kubernetes cluster for testing and shenanigans

User Guide - Quick Start: https://kind.sigs.k8s.io/docs/user/quick-start

To create a cluster with default name
```bash
kind create cluster
```

Create a cluster with a specific name
```bash
kind create cluster --name foo
```

List clusters
```bash
kind get clusters
```

Specify Kubernetes version
```bash
kind create cluster --image "kindest/node:$favoriteTag"
```
- pick your $favoriteTag from here: https://hub.docker.com/r/kindest/node/tags?page=1&ordering=last_updated

Export all logs from a cluster
```bash
kind exports logs $HOME/somedir
```

To delete a cluster with default name
```bash
kind delete cluster
```

To delete a cluster with specific name
```bash
kind delete cluster --name foo
```

Get the kubeconfig of a cluster
```bash
kind get kubeconfig --name foo
```
