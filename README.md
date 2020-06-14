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

An install consists of 5 parts in two files:

```
my-new-package/
  - releases.js
  - my-new-package.bash
```

1. Create Description
2. Fetch Releases
3. Version Check (semi-optional)
4. Update PATH

See these **examples**:

- https://github.com/webinstall/packages/blob/master/rg/
- https://github.com/webinstall/packages/blob/master/golang/

The `webinstall.dev` server uses the list of releases returned by
`<your-package>/releases.js` to generate a bash script with most necessary
variables and functions pre-defined.

You just fill in the blanks.

### 1. Create Description

Just copy the format from any of the existing packages. It's like this:

`my-new-package.bash`:

````
# title: Node.js
# homepage: https://nodejs.org
# tagline: JavaScript V8 runtime
# description: |
#   Node.js® is a JavaScript runtime built on Chrome's V8 JavaScript engine
# examples: |
#   ```bash
#   node -e 'console.log("Hello, World!")'
#   > Hello, World!
#   ```
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

```bash
# Define this if the package name is different from the command name (i.e. golang => go)
pkg_cmd_name="foobar"

# These are used for symlinks, PATH, and test commands
pkg_common_opt="$HOME/.local/opt/foobar"
pkg_common_bin="$HOME/.local/opt/foobar/bin"
pkg_common_cmd="$HOME/.local/opt/foobar/bin/foobar"

# These are the _real_ locations for the above
pkg_new_opt="$HOME/.local/opt/foobar-v$WEBI_VERSION"
pkg_new_bin="$HOME/.local/opt/foobar-v$WEBI_VERSION/bin"
pkg_new_cmd="$HOME/.local/opt/foobar-v$WEBI_VERSION/bin/foobar"
```

(required) A version check function that strips all non-version junk

```bash
pkg_get_current_version() {
    # foobar-v1.1.7 => 1.1.7
    echo "$(foobar --version | head -n 1 | sed 's:foobar-v::')"
}
```

For the rest of the functions you can like copy/paste from the examples:

```bash
pkg_format_cmd_version() {}     # Optional, pretty prints version

pkg_link_new_version() {}       # Required, may be empty for $HOME/.local/bin commands

pkg_pre_install() {             # Required, runs any webi_* commands
    webi_check                      # for $HOME/.local/opt tools
    webi_download                   # for things that have a releases.js
    webi_extract                    # for .xz, .tar.*, and .zip files
}

pkg_install() {}                # Required, usually just needs to rename extracted folder to
                                # "$HOME/.local/opt/$pkg_cmd_name-v$WEBI_VERSION"

pkg_post_install() {            # Required
    pkg_link_new_version            # should probably call pkg_link_new_version()
    webi_path_add "$pkg_common_bin" # should probably update PATH
}

pkg_post_install_message() {}   # Optional, pretty print a success message
```

## Script API

See `webi/template.bash`

These variables will be set by the server:

```
WEBI_PKG=example@v1
WEBI_NAME=example
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

```bash
WEBI_TMP=${WEBI_TMP:-"$(mktemp -d -t webinstall-foobar.XXXXXXXX)"}
```

```bash
webi_check              # Checks to see if the selected version is already installed (and re-links if so)
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
