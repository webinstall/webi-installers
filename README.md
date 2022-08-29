# [webi-installers](https://github.com/webinstall/webi-installers)

> [webi](https://webinstall.dev) is how developers install their tools

[![webinstall-dev-ogimage-github](https://user-images.githubusercontent.com/122831/129465590-136b5a8a-f8f5-4e8d-a010-784eaa9f21bb.png)](https://webinstall.dev)

- no `sudo`
- no package manager
- no messing with system permissions
- in short: no nonsense

```sh
curl https://webi.sh/webi | sh
```

This repository contains the primary and community-submitted packages for
[webinstall.dev](https://webinstall.dev).

# How webi works

- Contacts official release APIs for download URLs
- Selects the appropriate package version and archive format
- Installs to `$HOME/.local/opt` or `$HOME/.local/bin`, as appropriate.
- Updates `PATH` via `$HOME/.config/envman/PATH.env`
- Symlinks or copies current selected version

More technically:

1. `<package>/releases.js` transforms the package's release API into a common
   format
   - (i.e. HTML, CSV, TAB, or JSON into a specific JSON format)
   - common release APIs are in `_common/` (i.e. `_common/github.js`)
2. `_webi/bootstrap.sh` is a template that exchanges system information for a
   correct installer
   - constructs a user agent with os, cpu, and utility info (i.e. `macos`,
     `amd64`, can unpack `tar,zip,xz`)
3. `_webi/template.sh` is the base installer template with common functions for
   - checking versions
   - downloading & unpacking
   - updating PATH
   - (re-)linking directories
4. `<package>/install.sh` may provide functions to override `_webi/template.sh`
5. Recap:
   - `curl https://webi.sh/<pkg>` => `bootstrap-<pkg>.sh`
   - `sh bootstrap-<pkg>.sh` =>
     `https://webinstall.dev/api/installers/<pkg>@<ver>.sh?formats=zip,tar`
   - `sh install-<pkg>.sh` => download, unpack, move, link, update PATH

# Philosophy (for package authors / maintainers publishing with webi)

- Should install to `$HOME/.local/opt/<package>-<version>` or `$HOME/.local/bin`
- Should not need `sudo` (except perhaps for a one-time `setcap`, etc)
- Examples:
  - Full Packages:
    - Node.js: <https://github.com/webinstall/packages/tree/master/node>
    - Golang: <https://github.com/webinstall/packages/tree/master/golang>
    - PostgreSQL: <https://github.com/webinstall/packages/tree/master/postgres>
  - Single-Binary Installers:
    - Caddy: <https://github.com/webinstall/packages/tree/master/caddy>
    - Ripgrep: <https://github.com/webinstall/packages/tree/master/ripgrep>
    - Gitea: <https://github.com/webinstall/packages/tree/master/gitea>
  - Convenience Scripts:
    - Prettier: <https://github.com/webinstall/packages/tree/master/prettier>
    - Rust-lang: <https://github.com/webinstall/packages/tree/master/rustlang>
    - vim-sensible:
      <https://github.com/webinstall/packages/tree/master/vim-sensible>

## Creating an Installer

An install consists of 5 parts in 4 files:

```
my-new-package/
  - README.md (package info in frontmatter)
  - releases.js
  - install.sh (POSIX Shell)
  - install.ps1 (PowerShell)
```

1. Create Description
2. Fetch Releases
3. Version Check (semi-optional)
4. Update PATH

See these **examples**:

- https://github.com/webinstall/packages/blob/master/rg/
- https://github.com/webinstall/packages/blob/master/golang/

The `webinstall.dev` server uses the list of releases returned by
`<your-package>/releases.js` to generate a shell script with most necessary
variables and functions pre-defined.

You just fill in the blanks.

### TL;DR

Just create an empty directory and run the tests until you get a good result.

```sh
git clone git@github.com:webinstall/packages.git
pushd packages
npm install
```

```sh
mkdir -p ./new-package/
node _webi/test.js ./new-package/
```

### 1. Create Description

Just copy the format from any of the existing packages. It's like this:

`README.md`:

````md
---
title: Node.js
homepage: https://nodejs.org
tagline: |
  JavaScript V8 runtime
description: |
  Node.js® is a JavaScript runtime built on Chrome's V8 JavaScript engine
---

```sh
node -e 'console.log("Hello, World!")'
> Hello, World!
```
````

### 1. Fetch Releases

All you're doing in this step is just translating from one form of JSON or CSV
or TAB or whatever, to a format understood by `webi`.

- Using Github releases? See `ripgrep/releases.js` (which uses
  `_common/github.js`)
- Have a special format? See `golang/releases.js` or `node/releases.js`.

It looks like this:

`releases.js`:

```js
module.exports = function (request) {
  return github(request, owner, repo).then(function (all) {
    // if you need to do something special, you can do it here
    // ...
    return all;
  });
};
```

### 2. Bash Installer

1. Variables _you_ can set
2. Functions _you_ must define
3. Convenience / Helper Functions

(optional, if needed) Bash variables that you _may_ define:

```sh
# Define this if the package name is different from the command name (i.e. golang => go)
pkg_cmd_name="foobar"

# These are used for symlinks, PATH, and test commands
pkg_dst="$HOME/.local/opt/foobar"
pkg_dst_cmd="$HOME/.local/opt/foobar/bin/foobar"
#pkg_dst_bin="$(dirname "$pkg_dst_cmd")"

# These are the _real_ locations for the above
pkg_src="$HOME/.local/opt/foobar-v$WEBI_VERSION"
pkg_src_cmd="$HOME/.local/opt/foobar-v$WEBI_VERSION/bin/foobar"
#pkg_src_bin="$(dirname "$pkg_src_cmd")"
```

(required) A version check function that strips all non-version junk

```sh
pkg_get_current_version() {
    # foobar-v1.1.7 => 1.1.7
    echo "$(foobar --version | head -n 1 | sed 's:foobar-v::')"
}
```

For the rest of the functions you can copy/paste from the examples:

```sh
pkg_format_cmd_version() {}         # Override, pretty prints version

pkg_link                            # Override, replaces webi_link()

pkg_pre_install() {                 # Override, runs any webi_* commands
    webi_check                          # for $HOME/.local/opt tools
    webi_download                       # for things that have a releases.js
    webi_extract                        # for .xz, .tar.*, and .zip files
}

pkg_install() {}                    # Override, usually just needs to rename extracted folder to
                                    # "$HOME/.local/opt/$pkg_cmd_name-v$WEBI_VERSION"

pkg_post_install() {                # Override
    webi_path_add "$pkg_dst_bin"        # should probably update PATH
}

pkg_done_message() {}               # Override, pretty print a success message
```

## Script API

See `webi/template.sh`

These variables will be set by the server:

```sh
WEBI_PKG=example@v1
WEBI_TAG=v1
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

```sh
PKG_NAME=example
PKG_OSES=macos,linux,windows
PKG_ARCHES=amd64,arm64,x86
PKG_FORMATS=zip,xz
```

```sh
WEBI_TMP=${WEBI_TMP:-"$(mktemp -d -t webinstall-foobar.XXXXXXXX)"}
WEBI_SINGLE=""
```

```sh
webi_check              # Checks to see if the selected version is already installed (and re-links if so)
webi_download           # Downloads the selected release to $HOME/Downloads/webi/<package-name>.tar.gz
webi_extract            # Extracts the download to /tmp/<package-name>-<random>/
webi_path_add /new/path # Adds /new/path to PATH for bash, zsh, and fish
webi_pre_install        # Runs webi_check, webi_download, and webi_extract
webi_install            # Moves extracted files from $WEBI_TMP to $pkg_src
webi_link               # replaces any existing symlink with the currently selected version
webi_post_install       # Runs `webi_path_add $pkg_dst_bin`
```

# Roadmap

- Wrap release APIs to unify and expose
- [ ] Support more Windows packages
- [ ] Support arbitrary git urls (i.e. `@github.com/node/node`)
  - (maybe `ghi node/node` for github specifically)
- [ ] Support git as an archive format

<!--

# Windows Notes

```bat
set WEBI_HOST=https://webinstall.dev
```

Windows has curl too!?

```bat
curl.exe -sL https://webi.ms/node | powershell
```

And it's easy enough to ignore the execution policy

```bat
powershell -ExecutionPolicy Bypass install.ps1
```

And if we want something that looks as complicated as we expect Windows to be,
historically, we have options:

```bat
powershell "Invoke-Expression ( Invoke-WebRequest -UseBasicParsing https://webi.ms/node ).Contents"
```

```bat
powershell ( Invoke-WebRequest -UseBasicParsing https://webi.ms/node ).Contents | powershell
```

-->
