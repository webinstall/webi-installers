# @webinstall/packages

> WebInstall is how developers install their tools

```bash
curl https://webinstall.dev/webi | bash
```

This repository contains the primary and community-submitted packages for
[webinstall.dev](https://webinstall.dev).

# Installer Guidelines

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
        - Rust-lang: <https://github.com/webinstall/packages/tree/master/vim-sensible>

# How it works

- Contacts official release APIs for download URLs
- Selects the appropriate package version and archive format
- Installs to `$HOME/.local/`
- Updates `PATH` via `$HOME/.config/envman/PATH.env`
- Symlinks or copies current selected version

More technically:

1. `<package>/releases.js` transforms the package's release API into a common formatt
    - (i.e. HTML, CSV, TAB, or JSON into a specific JSON format)
    - common release APIs are in `_common/` (i.e. `_common/github.js`)
2. `_webi/bootstrap.sh` is a template that exchanges system information for a correct installer
    - contructs a user agent with os, cpu, and utility info (i.e. `macos`, `amd64`, can unpack `tar,zip,xz`)
3. `_webi/template.sh` is the base installer template with common functions for
    - checking versions
    - downloading & unpacking
    - updating PATH
    - (re-)linking directories
4. `<package>/install.sh` may provide functions to override `_webi/template.sh`
5. Recap:
    - `curl https://webinstall.dev/<pkg>` => `bootstrap-<pkg>.sh`
    - `bash bootstrap-<pkg>.sh` => `https://webinstall.dev/api/installers/<pkg>@<ver>.sh?formats=zip,tar`
    - `bash install-<pkg>.sh` => download, unpack, move, link, update PATH

## Creating an Installer

An install consists of 5 parts in 4 files:

```
my-new-package/
  - package.yash
  - releases.js
  - install.sh
  - install.bat
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

### TL;DR

Just create an empty directory and run the tests until you get a good result.

```bash
git clone git@github.com:webinstall/packages.git
pushd packages
npm install
```

```bash
mkdir -p ./new-package/
node _webi/test.js ./new-package/
```

### 1. Create Description

Just copy the format from any of the existing packages. It's like this:

`package.yash`:

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

END
````

This is a dumb format. We know. Historical accident (originally these were in
bash comments).

It's in the TODOs to replace this with either YAML or Markdown.

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
pkg_dst="$HOME/.local/opt/foobar"
pkg_dst_bin="$HOME/.local/opt/foobar/bin"
pkg_dst_cmd="$HOME/.local/opt/foobar/bin/foobar"

# These are the _real_ locations for the above
pkg_src="$HOME/.local/opt/foobar-v$WEBI_VERSION"
pkg_src_bin="$HOME/.local/opt/foobar-v$WEBI_VERSION/bin"
pkg_src_cmd="$HOME/.local/opt/foobar-v$WEBI_VERSION/bin/foobar"
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
WEBI_SINGLE=""
```

```bash
webi_check              # Checks to see if the selected version is already installed (and re-links if so)
webi_download           # Downloads the selected release to $HOME/Downloads/<package-name>.tar.gz
webi_extract            # Extracts the download to /tmp/<package-name>-<random>/
webi_path_add /new/path # Adds /new/path to PATH for bash, zsh, and fish
webi_pre_install        # Runs webi_check, webi_download, and webi_extract
webi_install            # Moves extracted files from $WEBI_TMP to $pkg_src
webi_link               # replaces any existing symlink with the currently selected version
webi_post_install       # Runs `webi_add_path $pkg_dst_bin`
```

# Roadmap

- Wrap release APIs to unify and expose
- [ ] Support arbitrary git urls (i.e. `@github.com/node/node`)
  - (maybe `ghi node/node` for github specifically)
- [ ] Support git as an archive format
