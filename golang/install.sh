#!/bin/sh
set -e
set -u

GOBIN="${HOME}/go"

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
    go version 2> /dev/null |
        head -n 1 |
        cut -d' ' -f3 |
        sed 's:go::'
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

    # Go's package directory (GOPATH) at ~/go must persist across version
    # upgrades. Unlike other tools, go-installed binaries are shared across
    # all Go versions, so ~/go is kept stable rather than being swapped to a
    # versioned directory on each upgrade.
    b_gobin_stable="${HOME}/.local/opt/go-bin"
    if [ ! -e "$GOBIN" ] && [ ! -L "$GOBIN" ]; then
        # New install: create ~/go as a real directory (not a symlink)
        mkdir -p "$GOBIN/bin"
    elif [ -L "$GOBIN" ]; then
        b_old_target="$(readlink "$GOBIN")"
        if [ "$b_old_target" != "$b_gobin_stable" ] && [ -d "$b_old_target" ]; then
            # Migrate from old versioned-symlink (e.g. go-bin-v1.14.2):
            # rename the versioned directory to the stable unversioned path
            # so that all installed tools are preserved on upgrade.
            mv "$b_old_target" "$b_gobin_stable"
            rm -f "$GOBIN"
            ln -s "$b_gobin_stable" "$GOBIN"
        elif [ ! -d "$b_old_target" ]; then
            # Symlink target is gone; recreate ~/go as a real directory
            rm -f "$GOBIN"
            mkdir -p "$GOBIN/bin"
        fi
        # If already pointing to the stable unversioned dir, do nothing
    fi
    # If $GOBIN is already a real directory, leave it alone
}

pkg_post_install() {
    pkg_link

    # web_path_add is defined in _webi/template.sh at https://github.com/webinstall/packages
    # Updates PATH with
    #       "$HOME/.local/opt/go"
    webi_path_add "$pkg_dst_bin"
    webi_path_add "$GOBIN/bin"
}

pkg_done_message() {
    echo "Installed 'go v$WEBI_VERSION' to ~/.local/opt/go"
}
