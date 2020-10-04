---
title: goreleaser
homepage: https://goreleaser.com
tagline: |
  goreleaser: Deliver Go binaries as fast and easily as possible
---

### Updating `goreleaser`

`webi goreleaser@stable`

Use the `@beta` tag for pre-releases.

## Cheat Sheet

> `goreleaser` builds Go binaries for serveral platforms, creates a GitHub release
> and then pushes a Homebrew formula to a tap repository. All that wrapped in your
> favourite CI.

To create an example `.goreleaser.yaml` file, and test the configuration:

```bash
goreleaser init
goreleaser --snapshot --skip-publish --rm-dist
```

You'll need to export a `GITHUB_TOKEN` or `GITLAB_TOKEN` environment variable, which should 
contain a valid GitHub token with the `repo` scope or GitLab token with `api` scope. It will 
be used to deploy releases to your GitHub/GitLab repository. You can create a token
[here](https://github.com/settings/tokens/new) for GitHub or 
[here](https://gitlab.com/profile/personal_access_tokens) for GitLab.

```bash
export GITHUB_TOKEN="YOUR_GITHUB_TOKEN"
```

or

```bash
export GITLAB_TOKEN="YOUR_GITLAB_TOKEN"
```

GoReleaser will use the latest [Git tag](https://git-scm.com/book/en/v2/Git-Basics-Tagging) of your 
repository. Create a tag and push it to GitHub:

```bash
git tag -a v0.1.0 -m "First release"
git push origin v0.1.0
```

Now you can run GoReleaser at the root of your repository:

```bash
goreleaser
```

That's all! Check your GitHub/GitLab project's release page.

### To cross-compile for Windows / Linux

```bash
brew install mingw-w64
brew install FiloSottile/musl-cross/musl-cross
```

```bash
GOARCH=amd64 GOOS=darwin                              go build -o unarr_darwin cmd/unarr/unarr.go
GOARCH=amd64 GOOS=windows CC=x86_64-w64-mingw32-gcc   go build -o unarr.exe cmd/unarr/unarr.go
GOARCH=amd64 GOOS=linux   CC=x86_64-linux-musl-gcc    go build -o unarr_linux_amd64 cmd/unarr/unarr.go
```

The linux in question would need the musl libs installed to run a musl bin

```bash
sudo apt-get install -y musl
```

```bash
- builds:
  - id: unarr-linux-x64
    main: ./cmd/unarr/unarr.go
    env:
      - CGO_ENABLED=1
      - CC=x86_64-linux-musl-gcc
    flags:
      - "-ldflags"
      - '-extldflags "-static"'
    goos:
      - linux
    goarch:
      - amd64
```