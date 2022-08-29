---
title: goreleaser
homepage: https://goreleaser.com
tagline: |
  goreleaser: Deliver Go binaries as fast and easily as possible
---

To update or switch versions, run `webi goreleaser@stable` (or `@v0.174`,
`@beta`, etc).

## Cheat Sheet

> `goreleaser` makes it easy to build versioned Go binaries for Mac, Linux,
> Windows, and Raspberry Pi, and to publish the ChangeLog and binaries to common
> release platforms including GitHub, Gitea, Gitlab, and Homebrew.

There's a lot that you can do with GoReleaser. These are the things that we've
found the most useful for the majority of projects:

- Basic Usage & Versioning
- Publishing Builds to GitHub
- Publishing to Gitea and Gitlab
- Building for RPi et al
- Building from one or more `cmd/`s
- Cross-Compiling with cgo
- Full `.goreleaser.yml` example

## Basic Usage & Versioning

To create an example `.goreleaser.yaml` file, and test the configuration:

```sh
goreleaser init
goreleaser --snapshot --skip-publish --rm-dist
```

- `--snapshot` allows "dirty" builds (when the repo has uncommitted changes)
- `--skip-publish` will NOT publish to GitHub, etc
- `--rm-dist` will automatically remove the `./dist/` directory

The default `.goreleaser.yml` works well for projects for which `package main`
is at the root.

GoReleaser provides version information. Here's a good, generic way to print it
out:

```go
package main

var (
	// these will be replaced by goreleaser
	version = "v0.0.0"
	date    = "0001-01-01T00:00:00Z"
	commit  = "0000000"
)

func main() {
	if len(os.Args) >= 2 && "version" == strings.TrimPrefix(os.Args[1]) {
		fmt.Printf("YOUR_CLI_NAME v%s %s (%s)\n", version, commit[:7], date)
	}

	// ...
}
```

### How to Publish Builds to GitHub

You'll need a **Personal Access Token** with the `repo` scope. \
You can get one at <https://github.com/settings/tokens/new>.

You can export the environment variable:

```sh
export GITHUB_TOKEN="YOUR_GITHUB_TOKEN"
```

Or place the token in the default config location:

```sh
~/.config/goreleaser/github_token
```

You can also set `env_files` in `.goreleaser.yml`:

```yml
env_files:
  github_token: ~/.config/goreleaser/github_token
```

Running GoReleaser without `--snapshot` must use the latest
[Git tag](https://git-scm.com/book/en/v2/Git-Basics-Tagging) of your repository.
Create a tag and push it to Git:

```sh
git tag -a v1.0.0 -m "First release"
git push origin v1.0.0
```

Running GoReleaser without `--skip-publish` will publish the builds:

```sh
goreleaser --rm-dist
```

Check the console output to make sure that there are no messages about a failed
publish. \
If all is well you should the git tag on the releases page updated with a ChangeLog
and the published binaries.

### How to Publish to Gitea and others

Gitea Token: https://try.gitea.io/user/settings/applications

```yml
env_files:
  gitea_token: ~/.config/goreleaser/gitea_token
gitea_urls:
  api: https://try.gitea.io/api/v1/
```

GitLab Token: https://gitlab.com/profile/personal_access_tokens

```yml
env_files:
  gitlab_token: ~/.config/goreleaser/gitlab_token
gitlab_urls:
  api: https://gitlab.com/api/v1/
```

Also see https://goreleaser.com/environment/

### How to Build for Raspberry Pi (ARM)

All of the Raspberry Pis are ARM processors and can run Linux. Most can run
Windows as well.

- RPi 4 is ARM 64, also known as `aarch64`, `arm64`, and `armv8`.
- RPi 3 could run `armv7` and `arm64`.
- RPi 2, RPi Zero, and RPi can run either `armv6` or `armv7`.

To build Go binaries for ARM, you'll need to update the `build` section of your
`.goreleases.yml`.

```yml
builds:
  - env:
      - CGO_ENABLED=0
    goos:
      - linux
      - windows
      - darwin
    goarch:
      - 386
      - amd64
      - arm
      - arm64
    goarm:
      - 6
      - 7
```

For information on other supported build options, such as BSD and ppc, see
[Go (Golang) GOOS and GOARCH](https://gist.github.com/asukakenji/f15ba7e588ac42795f421b48b8aede63).

### How to Build from the `cmd` Directory

By default GoReleaser assumes that the root of your package is `package main`.

If your `package main` is in a `cmd/` directory or you have multiple commands,
you should update your `builds` directive accordingly.

```yml
- builds:
    - id: command123
      main: ./cmd/command123/command123.go
      binary: command123
      goos:
        - linux
        - windows
        - darwin
      goarch:
        - amd64
        - arm64
    - id: other321
      main: ./cmd/other321/other321.go
      binary: other123
      goos:
        - linux
        - windows
        - darwin
      goarch:
        - amd64
        - arm64
```

### How to Cross-Compile cgo

> [cgo](https://golang.org/cmd/cgo/) is not Go - Dave Cheney

Most Go programs are "pure Go" and will cross-compile `CGO_ENABLED=0` without
any special configuration.

Some programs include C libraries, especially SQLite3 or 7z, and require
integration with C libraries.

#### Mac Cross-Compilers

From macOS you can easily cross-compile cgo for Windows and Linux.

Install [brew](https://webinstall.dev/brew), if needed:

```sh
curl -sS https://webi.sh/brew | sh
```

Install mingw and musl-cross: \
(this may take hours if pre-built binaries are not available)

```sh
brew install mingw-w64
brew install FiloSottile/musl-cross/musl-cross --with-aarch64 --with-arm # --with-mips --with-486
```

You may want to manually test compiling for multiple platforms before automating
it:

```sh
GOARCH=amd64 GOOS=darwin                              go build -o unarr_darwin cmd/unarr/unarr.go
GOARCH=amd64 GOOS=windows CC=x86_64-w64-mingw32-gcc   go build -o unarr.exe cmd/unarr/unarr.go
GOARCH=amd64 GOOS=linux   CC=x86_64-linux-musl-gcc    go build -o unarr_linux_amd64 cmd/unarr/unarr.go
GOARCH=arm64 GOOS=linux   CC=aarch64-linux-musl-gcc   go build -o unarr_linux_arm64 cmd/unarr/unarr.go
GOARCH=arm   GOOS=linux   CC=arm-linux-musl-gcc       go build -o unarr_linux_armv7 cmd/unarr/unarr.go
```

If you have simple instructions for how to set up cross-compiling from Windows
or Linux, please let us know.

#### Build Changes

You'll need to manually create a different `builds` item for each unique `id`:

```yml
- builds:
    - id: unarr-linux-x64
      main: ./cmd/unarr/unarr.go
      env:
        - CGO_ENABLED=1
        - CC=x86_64-linux-musl-gcc
      flags:
        - '-ldflags'
        - '-extldflags "-static"'
      goos:
        - linux
      goarch:
        - amd64
    - id: unarr-linux-aarch64
      main: ./cmd/unarr/unarr.go
      env:
        - CGO_ENABLED=1
        - CC=aarch64-linux-musl-gcc
      flags:
        - '-ldflags'
        - '-extldflags "-static"'
      goos:
        - linux
      goarch:
        - arm64
    - id: unarr-linux-armv7
      main: ./cmd/unarr/unarr.go
      env:
        - CGO_ENABLED=1
        - CC=arm-linux-musleabi-gcc
      flags:
        - '-ldflags'
        - '-extldflags "-static"'
      goos:
        - linux
      goarch:
        - arm
      goarm:
        - 7
    - id: unarr-windows-x64
      main: ./cmd/unarr/unarr.go
      env:
        - CGO_ENABLED=1
        - CC=x86_64-w64-mingw32-gcc
      flags:
        - '-ldflags'
        - '-extldflags "-static"'
      goos:
        - linux
      goarch:
        - amd64
```

If you compile without `-static`, you will need the `musl` libraries to run on
(non-Alpine) Linuxes:

```sh
sudo apt-get install -y musl
```

### Full Example Config

The full file will look something like this:

`.goreleaser.yml`

```yml
project_name: exampleproject
before:
  hooks:
    - go mod download
    - go generate ./...
builds:
  - env:
      - CGO_ENABLED=0
    goos:
      - linux
      - windows
      - darwin
    goarch:
      - 386
      - amd64
      - arm
      - arm64
    goarm:
      - 6
      - 7
archives:
  - replacements:
      darwin: Darwin
      linux: Linux
      windows: Windows
      386: i386
      amd64: x86_64
    format_overrides:
      - goos: windows
        format: zip
checksum:
  name_template: 'checksums.txt'
snapshot:
  name_template: '{{ .Tag }}-next'
changelog:
  sort: asc
  filters:
    exclude:
      - '^docs:'
      - '^test:'
```
