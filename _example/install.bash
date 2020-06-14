#!/bin/bash

# TODO: migrate from shmatter to frontmarker

set -e
set -u

## The defaults can be assumed if these are not set

## The command name may be different from the package name
## (i.e. golang => go, rustlang => cargo, ripgrep => rg)
## Note: $HOME may contain special characters and should alway be quoted

pkg_cmd_name="xmpl"

## Some of these directories may be the same, in some cases
#pkg_dst="$HOME/.local/opt/xmpl"
#pkg_dst_bin="$HOME/.local/opt/xmpl/bin"
#pkg_dst_cmd="$HOME/.local/opt/xmpl/bin/xmpl"

#pkg_src="$HOME/.local/opt/xmpl-v$WEBI_VERSION"
#pkg_src_bin="$HOME/.local/opt/xmpl-v$WEBI_VERSION/bin"
#pkg_src_cmd="$HOME/.local/opt/xmpl-v$WEBI_VERSION/bin/xmpl"

# Different packages represent the version in different ways
# ex: node v12.8.0 (leading 'v')
# ex: go1.14 (no space, nor trailing '.0's)
# ex: flutter 1.17.2 (plain)
pkg_format_cmd_version() {
    my_version=$1
    echo "$pkg_cmd_name v$my_version"
}

# The version info should be reduced to a sortable version, without any leading characters
# (i.e. v12.8.0 => 12.8.0, go1.14 => 1.14, 1.12.13+hotfix => 1.12.13+hotfix)
pkg_get_current_version() {
    echo "$(xmpl --version 2>/dev/null | head -n 1 | cut -d' ' -f2)"
}

# For (re-)linking to the desired installed version
# (for example: 'go' is special and needs both $HOME/go and $HOME/.local/opt/go)
# (others like 'rg', 'hugo', and 'caddy' are single files that just get replaced)
pkg_link_src_dst() {
    rm -rf "$pkg_dst"
    ln -s "$pkg_src" "$pkg_dst"
}

pkg_pre_install() {
    # web_* are defined in webi/template.bash at https://github.com/webinstall/packages

    # if selected version is installed, re-link it and quit
    webi_check

    # will save to ~/Downloads/$WEBI_PKG_FILE by default
    webi_download

    # supported formats (.xz, .tar.*, .zip) will be extracted to $WEBI_TMP
    webi_extract
}

# For installing from the extracted package tmp directory
pkg_install() {
    pushd "$WEBI_TMP" 2>&1 >/dev/null

        # remove the versioned folder, just in case it's there with junk
        rm -rf "$pkg_src"

        # rename the entire extracted folder to the new location
        # (this will be "$HOME/.local/opt/xmpl-v$WEBI_VERSION" by default)
        mv ./"$pkg_cmd_name"* "$pkg_src"

    popd 2>&1 >/dev/null
}

# For updating PATHs and installing companion tools
pkg_post_install() {
    pkg_link_src_dst

    # web_path_add is defined in webi/template.bash at https://github.com/webinstall/packages
    webi_path_add "$pkg_dst_bin"
}

pkg_post_install_message() {
    echo "Installed 'example' as 'xmpl'"
}
