---
title: Syft
homepage: https://github.com/anchore/syft/
tagline: |
  Syft is a CLI tool and library for generating a Software Bill of Materials
  from container images and filesystems.
---

To update or switch versions, run `webi syft@stable` (or `@v0.101.1`, `@beta`,
etc)

### Files

```
~/.config/envman/PATH.env
~/.syft.yaml
~/.local/bin/syft
```

## Cheat Sheet

> Generates SBOMs for container images, filesystems, archives, and more to
> discover packages and libraries. Supports OCI, Docker and Singularity image
> formats. Convert between SBOM formats, such as CycloneDX, SPDX, and Syft's own
> format.

### To generate an SBOM for a container image:

```sh
syft <image>
```

### To take into account the contents of all image layers:

```sh
syft <image> --scope all-layers
```
