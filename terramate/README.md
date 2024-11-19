---
title: Terramate
homepage: https://github.com/terramate-io/terramate
tagline: |
  Terramate simplifies managing large-scale Terraform codebases with a focus on automation and scalability.
---

To update or switch versions, run `webi terramate@stable` (or `@v1.0.0`,
`@beta`, etc).

## Cheat Sheet

The information in this section is a copy of the preflight requirements and
common command-line arguments from Terramate
(https://github.com/terramate-io/terramate).

> `Terramate` enables scalable automation for Terraform by providing a robust
> framework for managing multiple stacks, generating code, and executing
> targeted workflows.

### Preflight check

Ensure that your environment meets the following requirements to use Terramate
effectively:

- **Terraform installed**: Terramate integrates with Terraform; ensure you have
  the required version installed.
- **Go (optional)**: Needed if you are building Terramate from source.
- **Set up your PATH**: Add Terramate to your PATH for easy access.

To install and verify Terramate:

```sh
# Install Terramate using your preferred method
webi terramate@stable

# Verify installation
terramate version
```
