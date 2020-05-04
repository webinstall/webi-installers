# packages

Primary and community-submitted packages for
[webinstall.dev](https://webinstall.dev)

# Guidelines

- Should install to `./local/opt/<package>-<version>`
- Should not need `sudo` (except perhaps for a one-time `setcap`, etc)
- Follow the example of
  <https://github.com/webinstall/packages/tree/master/ripgrep>,
  <https://github.com/webinstall/packages/tree/master/node>, or
  <https://github.com/webinstall/packages/tree/master/golang>

## Creating an Installer

An install consists of 4 parts:

1. Generate a list of releases by OS and ARCH
   - For a Github releases example, see `ripgrep/releases.js` and
     `_common/github.js`
2. A bash version check (to skip downloading if already installed)
   - typically just 1 unique line of bash
3. A bash install (move files from the archive (zip, tar) to \$HOME/.local)
   - also typically just 1 unique line of bash
4. Update PATH
   - the `webi_path_add` bash function will work for bash, zsh, and fish

The `webinstall.dev` server uses the list of releases returned by
`<your-package>/releases.js` to generate a bash script with most necessary
variables and functions pre-defined.

You just fill in the blanks.

## Script API

See `webi/template.bash`

These variables will be set by the server:

```
WEBI_PKG=example@v1
WEBI_NAME=example
WEBI_HOST=https://webinstall.dev
WEBI_RELEASES=https://webinstall.dev/api/releases/example@v1?os=macos&arch=amd64&pretty=true
WEBI_CSV=v1.0.2,
WEBI_VERSION=1.0.2
WEBI_MAJOR=1
WEBI_MINOR=0
WEBI_PATCH=2
WEBI_LTS=
WEBI_CHANNEL=stable
WEBI_EXT=tar
WEBI_PKG_URL=https://cdn.example.com/example-macos-amd64.tar.gz
WEBI_PKG_FILE=example-macos-amd64.tar.gz
```

```bash
WEBI_TMP=${WEBI_TMP:-"$(mktemp -d -t webinstall-foobar.XXXXXXXX)"}
```

```bash
webi_download           # Downloads the selected release to $HOME/Downloads/<package-name>.tar.gz
webi_extract            # Extracts the download to /tmp/<package-name>-<random>/
webi_path_add /new/path # Adds /new/path to PATH for bash, zsh, and fish
```

# Roadmap

- Wrap release APIs to unify and expose
  - [x] Golang <https://golang.org/dl/?mode=json>
  - [x] Node <https://nodejs.org/dist/index.tab>
  - [x] Flutter
        <https://storage.googleapis.com/flutter_infra/releases/releases_linux.json> -
        Started at
        <https://github.com/webinstall/packages/blob/master/flutter/versions.js>
  - [ ] git
    - Note: do all platforms expose tar/zip releases with the same URLs?
  - [ ] npm
  - [x] github (see ripgrep)
  - [x] gitea (see serviceman)
- [ ] Support git urls (i.e. `@github.com/node/node`)
  - (maybe `ghi node/node` for github specifically)
