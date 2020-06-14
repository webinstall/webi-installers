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

GOBIN="${HOME}/go"
GOBIN_REAL="${HOME}/.local/opt/go-bin-v${WEBI_VERSION}"

# The package is 'golang', but the command is 'go'
pkg_cmd_name="go"

# NOTE: pkg_* variables can be defined here
#       pkg_cmd_name
#       pkg_src, pkg_src_bin, pkg_src_cmd
#       pkg_dst, pkg_dst_bin, pkg_dst_cmd
#
# Their defaults are defined in webi/template.bash at https://github.com/webinstall/packages

pkg_get_current_version() {
    # 'go version' has output in this format:
    #       go version go1.14.2 darwin/amd64
    # This trims it down to just the version number:
    #       1.14.2
    echo "$(go version 2>/dev/null | head -n 1 | cut -d' ' -f3 | sed 's:go::')"
}

pkg_format_cmd_version() {
    # 'go v1.14.0' will be 'go1.14'
    my_version=$(echo "$1" | sed 's:\.0::g')
    echo "${pkg_cmd_name}${my_version}"
}

pkg_link_src_dst() {
    # 'pkg_dst' will default to $HOME/.local/opt/go
    # 'pkg_src' will be the installed version, such as to $HOME/.local/opt/go-v1.14.2
    rm -rf "$pkg_dst"
    ln -s "$pkg_src" "$pkg_dst"

    # Go has a special $GOBIN

    # 'GOBIN' is set above to "${HOME}/go"
    # 'GOBIN_REAL' will be "${HOME}/.local/opt/go-bin-v${WEBI_VERSION}"
    rm -rf "$GOBIN"
    mkdir -p "$GOBIN_REAL/bin"
    ln -s "$GOBIN_REAL" "$GOBIN"
}

pkg_pre_install() {
    # web_* are defined in webi/template.bash at https://github.com/webinstall/packages

    # multiple versions may be installed
    # if one already matches, it will simply be re-linked
    webi_check

    # the download is quite large - hopefully you have wget installed
    # will go to ~/Downloads by default
    webi_download

    # Multiple formats are supported: .xz, .tar.*, and .zip
    # will be extracted to $WEBI_TMP
    webi_extract
}

pkg_install() {
    pushd "$WEBI_TMP" 2>&1 >/dev/null

        # remove the versioned folder, just in case it's there with junk
        rm -rf "$pkg_src"

        # rename the entire extracted folder to the new location
        # (this will be "$HOME/.local/opt/go-v$WEBI_VERSION" by default)
        mv ./"$pkg_cmd_name"* "$pkg_src"

    popd 2>&1 >/dev/null
}

pkg_post_install() {
    pkg_link_src_dst

    # web_path_add is defined in webi/template.bash at https://github.com/webinstall/packages
    # Updates PATH with
    #       "$HOME/.local/opt/go"
    webi_path_add "$pkg_dst_bin"
    webi_path_add "$GOBIN/bin"

    # Install x go
    echo "Installing go extended tools (goimports, gorename, etc)"
    "$pkg_dst_cmd" get golang.org/x/tools/cmd/goimports > /dev/null 2>/dev/null
    "$pkg_dst_cmd" get golang.org/x/tools/cmd/gorename > /dev/null 2>/dev/null
    "$pkg_dst_cmd" get golang.org/x/tools/cmd/gotype > /dev/null 2>/dev/null
    "$pkg_dst_cmd" get golang.org/x/tools/cmd/stringer > /dev/null 2>/dev/null
}

pkg_post_install_message() {
    echo "Installed 'go' (and go tools)"
}
