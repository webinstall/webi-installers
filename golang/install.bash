#!/bin/bash

# title: Go
# homepage: https://golang.org
# tagline: The Go Programming Language tools
# description: |
#   Go is an open source programming language that makes it easy to build simple, reliable, and efficient software.
# examples: |
#   ```bash
#   mkdir -p hello/
#   pushd hello/
#   ```
#
#   ```bash
#   cat << EOF >> main.go
#   package main
#
#   import (
#     "fmt"
#   )
#
#   func main () {
#     fmt.Println("Hello, World!")
#   }
#   EOF
#   ```
#
#   ```bash
#   go fmt ./...
#   go build .
#   ./hello
#   > Hello, World!
#   ```

set -e
set -u

###################
# Install go #
###################

new_go="${HOME}/.local/opt/go-v${WEBI_VERSION}/bin/go"
common_go_home="${HOME}/.local/opt/go"
new_go_home="${HOME}/.local/opt/go-v${WEBI_VERSION}"
common_go_bin="${HOME}/go"
new_go_bin="${HOME}/.local/opt/go-bin-v${WEBI_VERSION}"

update_go_home() {
    rm -rf "$common_go_home"
    ln -s "$new_go_home" "$common_go_home"
    # TODO get better output from pathman / output the path to add as return to webi bootstrap
    webi_path_add "$common_go_home/bin"

    rm -rf "$common_go_bin"
    ln -s "$new_go_bin" "$common_go_bin"
    webi_path_add "$common_go_bin/bin"
}

if [ -x "$new_go_home/bin/go" ]; then
  update_go_home
  exit 0
fi

# Test for existing version
set +e
cur_go="$(command -v go)"
set -e
if [ -n "$cur_go" ]; then
  cur_ver=$(go version | cut -d' ' -f3 | sed 's:go::')
  if [ "$cur_ver" == "$(echo $WEBI_VERSION | sed 's:\.0::g')" ]; then
    echo "go v$WEBI_VERSION already installed at $cur_go"
    exit 0
  elif [ "$cur_go" != "$new_go" ]; then
    echo "WARN: possible conflict with go v$WEBI_VERSION at $cur_go"
  fi
fi


# Note: this file is `source`d by the true installer and hence will have the webi functions

# because we created releases.js we can use webi_download()
# downloads go to ~/Downloads
webi_download

# because this is tar or zip, we can webi_extract()
# extracts to the WEBI_TMP directory, raw (no --strip-prefix)
webi_extract

pushd "$WEBI_TMP" 2>&1 >/dev/null
    echo Installing go v${WEBI_VERSION} as "$new_go"

    # simpler for single-binary commands
    #mv ./example*/bin/example "$HOME/.local/bin"

    # best for packages and toolchains
    rm -rf "$new_go_home"
    if [ -n "$(command -v rsync 2>/dev/null | grep rsync)" ]; then
      rsync -Krl ./go*/ "$new_go_home/" 2>/dev/null
    else
      cp -Hr ./go*/* "$new_go_home/" 2>/dev/null
      cp -Hr ./go*/.* "$new_go_home/" 2>/dev/null
    fi
    rm -rf ./go*

    # Install x go
    $new_go_home/bin/go get golang.org/x/tools/cmd/goimports > /dev/null 2>/dev/null
    $new_go_home/bin/go get golang.org/x/tools/cmd/gorename > /dev/null 2>/dev/null
    $new_go_home/bin/go get golang.org/x/tools/cmd/gotype > /dev/null 2>/dev/null
    $new_go_home/bin/go get golang.org/x/tools/cmd/stringer > /dev/null 2>/dev/null
popd 2>&1 >/dev/null

###################
#   Update PATH   #
###################

update_go_home

echo "Installed 'go' (and go tools)"
echo ""
