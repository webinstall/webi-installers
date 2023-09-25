---
title: Grype
homepage: https://github.com/anchore/grype/
tagline: |
 Grype is a vulnerability scanner for container images and filesystems.  
---

To update or switch versions, run `webi grype@stable` (or `@v0.6`, `@beta`,
etc)

## Cheat Sheet

> It also helps find vulnerabilites for major operating system and language-specific packages.
> Supports Docker, OCI and Singularity image formats, OpenVEX support for filtering and augmenting scanning results.
> Works with `syft`, a powerful `SBOM` (software bill of materials) tool for container images and filesystems

### To scan for vulnerabilities in an image:

```sh
grype <image>
```

### To scan all image layers

```sh
grype <image> --scope all-layers
```

### To run grype from a Docker container so it can scan a running container

```sh
docker run --rm \
--volume /var/run/docker.sock:/var/run/docker.sock \
--name Grype anchore/grype:latest \
$(ImageName):$(ImageTag)
```
