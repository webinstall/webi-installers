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

```
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
```

### 1. Fetch Releases

All you're doing in this step is just translating from one form of JSON or CSV or TAB or whatever, to a format understood by `webi`.

- Using Github releases? See `ripgrep/releases.js` (which uses `_common/github.js`)
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

### 2. Version Check (semi-optional)

If the thing is already installed, we don't need to download and install it again.

You create a version check that looks like this:

```
    # if the output is "foobar 1.3.4", we just need the "1.3.4"
    cur_ver=$(foobar --version | cut -d ' ' -f 2)
```

And then you wrap it in some **boilerplate** (copy/paste/replace) that looks like this:

```
new_foobar="${HOME}/.local/bin/foobar"

# Test for existing version
set +e
current_foobar="$(command -v foobar)"
set -e
if [ -n "$current_foobar" ]; then
  # if the output is "foobar 1.3.4", we just need the "1.3.4"
  cur_ver=$(foobar --version | cut -d ' ' -f 2)
  if [ "$cur_ver" == "$WEBI_VERSION" ]; then
    echo "foobar v$WEBI_VERSION already installed at $current_foobar"
    exit 0
  elif [ "$current_foobar" != "$new_foobar" ]; then
    echo "WARN: possible conflict with foobar v$WEBI_VERSION at $current_foobar"
  fi
fi
```

### 3. Move files to $HOME/.local

The `webi_download` and `webi_extract` functions will handle download and unpacking.
All you have to do is move your files into the right place.

If you have a single binary that'll look like this:

```
    mv ./foobar-*/bin/foobar "$HOME/.local/bin/"
```

If you have something with more parts it'll look like this:

```
    if [ -n "$(command -v rsync 2>/dev/null | grep rsync)" ]; then
      rsync -Krl ./foobar*/ "$new_foobar_home/" 2>/dev/null
    else
      cp -Hr ./foobar*/* "$new_foobar_home/" 2>/dev/null
      cp -Hr ./foobar*/.* "$new_foobar_home/" 2>/dev/null
    fi
```

### 4. Update PATH

Typically speaking, `$HOME/.local/bin` will be added to the PATH for you.

However, you should call `webi_path_add` to add any special paths.

Again, just look at the examples.

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
