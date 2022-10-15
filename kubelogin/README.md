---
title: Kubelogin
homepage: https://github.com/Azure/kubelogin
tagline: |
  kubelogin: A client-go credential (exec) plugin implementing azure authentication.
---

To update or switch versions, run `webi example@stable` (or `@v0.0.20` etc).

## Cheat Sheet

> `kubelogin` is a client-go credential (exec) plugin implementing azure authentication. This plugin provides features that are not available in kubectl. It is supported on kubectl v1.11+.

Supported login methods:
* [Device code flow (interactive)](https://github.com/Azure/kubelogin#device-code-flow-interactive)
* [Service principal login flow (non interactive)](https://github.com/Azure/kubelogin#service-principal-login-flow-non-interactive)
* [User Principal login flow (non interactive)](https://github.com/Azure/kubelogin#user-principal-login-flow-non-interactive)
* [Managed Service Identity (non interactive)](https://github.com/Azure/kubelogin#managed-service-identity-non-interactive)
* [Azure CLI token login (non interactive)](https://github.com/Azure/kubelogin#azure-cli-token-login-non-interactive)
* [Azure Workload Federated Identity (non interactive)](https://github.com/Azure/kubelogin#azure-workload-federated-identity-non-interactive)

Example: Uses an access token from Azure CLI to log in.

```sh
kubelogin convert-kubeconfig -l azurecli
```

### Add Baz Highlighting

To run foo with both bar and baz highlighting turned on:

```sh
foo --bar=baz
```
