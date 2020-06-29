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

pkg_link() {
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

pkg_post_install() {
    pkg_link

    # web_path_add is defined in _webi/template.sh at https://github.com/webinstall/packages
    # Updates PATH with
    #       "$HOME/.local/opt/go"
    webi_path_add "$pkg_dst_bin"
    webi_path_add "$GOBIN/bin"

    # Install x go
    echo "Building go language tools..."
    echo gopls
    "$pkg_dst_cmd" get golang.org/x/tools/gopls@latest > /dev/null #2>/dev/null
    echo gotags
    "$pkg_dst_cmd" get github.com/jstemmer/gotags > /dev/null #2>/dev/null
    echo goimports
    "$pkg_dst_cmd" get golang.org/x/tools/cmd/goimports > /dev/null #2>/dev/null
    echo gorename
    "$pkg_dst_cmd" get golang.org/x/tools/cmd/gorename > /dev/null #2>/dev/null
    echo gotype
    "$pkg_dst_cmd" get golang.org/x/tools/cmd/gotype > /dev/null #2>/dev/null
    echo stringer
    "$pkg_dst_cmd" get golang.org/x/tools/cmd/stringer > /dev/null #2>/dev/null
}

pkg_done_message() {
    echo "Installed 'go' v$WEBI_VERSION to ~/.local/opt/go"
    echo "Installed go 'x' tools to GOBIN=\$HOME/go/bin"
}
