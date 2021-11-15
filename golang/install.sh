#!/bin/bash
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
# Their defaults are defined in _webi/template.sh at https://github.com/webinstall/packages

function pkg_get_current_version() {
    # 'go version' has output in this format:
    #       go version go1.14.2 darwin/amd64
    # This trims it down to just the version number:
    #       1.14.2
    go version 2> /dev/null |
        head -n 1 |
        cut -d' ' -f3 |
        sed 's:go::'
}

function pkg_format_cmd_version() {
    # 'go v1.14.0' will be 'go1.14'
    my_version=$(echo "$1" | sed 's:\.0::g')
    echo "${pkg_cmd_name}${my_version}"
}

function pkg_link() {
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

function pkg_post_install() {
    pkg_link

    # web_path_add is defined in _webi/template.sh at https://github.com/webinstall/packages
    # Updates PATH with
    #       "$HOME/.local/opt/go"
    webi_path_add "$pkg_dst_bin"
    webi_path_add "$GOBIN/bin"

    # Install x go
    echo "Building go language tools..."
    export GO111MODULE=on

    # See https://pkg.go.dev/mod/golang.org/x/tools?tab=packages

    my_install="install"
    # note: we intend a lexical comparison, so this is correct
    #shellcheck disable=SC2072
    if [[ ${WEBI_VERSION} < "1.16" ]]; then
        my_install="get"
    fi

    echo ""
    echo godoc
    "$pkg_dst_cmd" "${my_install}" golang.org/x/tools/cmd/godoc@latest > /dev/null #2>/dev/null

    echo ""
    echo gopls
    "$pkg_dst_cmd" "${my_install}" golang.org/x/tools/gopls@latest > /dev/null #2>/dev/null

    echo ""
    echo guru
    "$pkg_dst_cmd" "${my_install}" golang.org/x/tools/cmd/guru@latest > /dev/null #2>/dev/null

    echo ""
    echo golint
    "$pkg_dst_cmd" "${my_install}" golang.org/x/lint/golint@latest > /dev/null #2>/dev/null

    echo ""
    echo goimports
    "$pkg_dst_cmd" "${my_install}" golang.org/x/tools/cmd/goimports@latest > /dev/null #2>/dev/null

    echo ""
    echo gomvpkg
    "$pkg_dst_cmd" "${my_install}" golang.org/x/tools/cmd/gomvpkg@latest > /dev/null #2>/dev/null

    echo ""
    echo gorename
    "$pkg_dst_cmd" "${my_install}" golang.org/x/tools/cmd/gorename@latest > /dev/null #2>/dev/null

    echo ""
    echo gotype
    "$pkg_dst_cmd" "${my_install}" golang.org/x/tools/cmd/gotype@latest > /dev/null #2>/dev/null

    echo ""
    echo stringer
    "$pkg_dst_cmd" "${my_install}" golang.org/x/tools/cmd/stringer@latest > /dev/null #2>/dev/null

    echo ""
}

function pkg_done_message() {
    echo "Installed 'go v$WEBI_VERSION' to ~/.local/opt/go"
    # note: literal $HOME on purpose
    #shellcheck disable=SC2016
    echo 'Installed go "x" tools to GOBIN=$HOME/go/bin'
}
