---
title: Grype
homepage: https://github.com/anchore/grype/
tagline: |
  Grype is a vulnerability scanner for container images and filesystems.
---

To update or switch versions, run `webi grype@stable` (or `@v0.6`, `@beta`, etc)

### Files

```text
~/.config/envman/PATH.env
~/.grype.yaml
~/.local/bin/grype
```

## Cheat Sheet

> It also helps find vulnerabilities for major operating system and
> language-specific packages. Supports Docker, OCI and Singularity image
> formats, OpenVEX support for filtering and augmenting scanning results. Works
> with `syft`, a powerful `SBOM` (software bill of materials) tool for container
> images and file systems

### How to for vulnerabilities in an image

```sh
grype <image>
```

### How to scan all image layers

```sh
grype <image> --scope all-layers
```

### How to scan a running container

```sh
docker run --rm \
    --volume /var/run/docker.sock:/var/run/docker.sock \
    --name Grype anchore/grype:latest \
    my_image_name:my_image_tag
```
