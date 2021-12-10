---
title: eksctl
homepage: https://github.com/weaveworks/eksctl
tagline: |
  The official CLI for Amazon EKS
---

To update or switch versions, run `webi example@stable` (or `@v2`, `@beta`,
etc).

### Files

These are the files / directories that are created and/or modified with this
install:

```txt
~/.config/envman/PATH.env
~/.local/bin/eksctl
~/.local/opt/eksctl
```

## Cheat Sheet

> From the `eksctl` ReadMe:
> You can create a cluster in minutes with just one command – eksctl create cluster!
> AWS Account
> You will need to have AWS API credentials configured. What works for AWS CLI or any other tools (kops, Terraform etc), should be sufficient. You can use ~/.aws/credentials file or environment variables. For more information read AWS documentation.


You will also need AWS IAM Authenticator for Kubernetes command (either aws-iam-authenticator or aws eks get-token (available in version 1.16.156 or greater of AWS CLI) in your PATH.


The IAM account used for EKS cluster creation should have these minimal access levels.


To run eksctl:

```bash
eksctl
```

### Add Baz Highlighting

To run eksctl with both bar and baz highlighting turned on:

```bash
eksctl --bar=baz
```

### Further Reading and Direct Link to Original ReadMe:
https://github.com/weaveworks/eksctl