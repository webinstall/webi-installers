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
#   <br/>   
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
#   <br/>   
#
#   ```bash
#   go fmt ./...
#   go build .
#   ./hello
#   > Hello, World!
#   ```

set -e
set -u

# Use the script's first argument or the supplied WEBI_VERSION or ''
WEBI_VERSION=${1:-${WEBI_VERSION:-}}

# Set a temporary directory, if not already set
WEBI_TMP=${WEBI_TMP:-"$(mktemp -d -t webinstall-go.XXXXXXXX)"}

###################
#  Get WEBI vars  #
###################

# The WEBI bootstrap will define these
# but each script should be testable in its own right

if [ -z "${WEBI_PKG_URL:-}" ]; then
  release_tab="${WEBI_HOST}/api/releases/golang@${WEBI_VERSION:-}.csv?os=$(uname -s)&arch=$(uname -m)&ext=tar&limit=1"
  WEBI_CSV=$(curl -fsSL "$release_tab" -H "User-Agent: $(uname -a)")
  WEBI_CHANNEL=$(echo $WEBI_CSV | cut -d ',' -f 3)
  if [ "error" == "$WEBI_CHANNEL" ]; then
     echo "could not find release for go v${WEBI_VERSION}"
     exit 1
  fi
  WEBI_VERSION=$(echo $WEBI_CSV | cut -d ',' -f 1)
  WEBI_PKG_URL=$(echo $WEBI_CSV | cut -d ',' -f 9)
  WEBI_PKG_FILE="$WEBI_TMP/$(echo $WEBI_PKG_URL | sed s:.*/::)"
fi

###################
# Install go #
###################

new_go_home="${HOME}/.local/opt/go-v${WEBI_VERSION}"
new_go="${HOME}/.local/opt/go-v${WEBI_VERSION}/bin/go"

# Test for existing version 
set +e
cur_go="$(command -v go)"
set -e
if [ -n "$cur_go" ]; then
  # TODO this is still sometimes wrong (i.e. 1.14 = 1.14.0)
  cur_ver=$(go version | cut -d' ' -f3 | sed 's:go::')
  if [ "$cur_ver" == "$(echo $WEBI_VERSION | sed 's:\.0::g')" ]; then
    echo "go v$WEBI_VERSION already installed at $cur_go"
    exit 0
  elif [ "$cur_go" != "$new_go" ]; then
    echo "WARN: possible conflict with go v$WEBI_VERSION at $cur_go"
  fi
fi

# TODO move download to the webi bootstrap
echo Downloading go v"${WEBI_VERSION}" from "${WEBI_PKG_URL}"
curl -fsSL "${WEBI_PKG_URL}" -o "${WEBI_PKG_FILE}"
pushd "${WEBI_TMP}" 2>&1 >/dev/null
        echo Installing go v${WEBI_VERSION} as "$new_go" 
	tar xf "${WEBI_PKG_FILE}"
        rm "${WEBI_PKG_FILE}"

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

        # Install x go
        $new_go_home/bin/go get golang.org/x/tools/cmd/goimports > /dev/null 2>/dev/null
        $new_go_home/bin/go get golang.org/x/tools/cmd/gorename > /dev/null 2>/dev/null
        $new_go_home/bin/go get golang.org/x/tools/cmd/gotype > /dev/null 2>/dev/null
        $new_go_home/bin/go get golang.org/x/tools/cmd/stringer > /dev/null 2>/dev/null
popd 2>&1 >/dev/null

###################
#   Update PATH   #
###################

# TODO get better output from pathman / output the path to add as return to webi bootstrap
pathman add "$new_go_home"
pathman add "$HOME/go/bin/"
echo "Installed 'go' (and go tools)"
echo ""
