#!/bin/sh
set -e
set -u

pkg_cmd_name="gitea"
pkg_src_cmd="$HOME/.local/opt/gitea-v$WEBI_VERSION/gitea"
pkg_dst_cmd="$HOME/.local/opt/gitea/gitea"

pkg_get_current_version() {
    # 'gitea version' has output in this format:
    #       v2.1.0 h1:pQSaIJGFluFvu8KDGDODV8u4/QRED/OPyIR+MWYYse8=
    # This trims it down to just the version number:
    #       2.0.0
    gitea --version 2> /dev/null | head -n 1 | cut -d' ' -f3
}

pkg_link() {
    # although gitea is a single command it must be put in its own directory
    # because it will always resolve its working path to its location,
    # regardless of where it was started, where its config file lives, etc.
    rm -rf "$pkg_dst_cmd"
    mkdir -p "$pkg_dst_bin/custom"
    chmod a+x "$pkg_src_cmd"
    ln -s "$pkg_src_cmd" "$pkg_dst_cmd"
}

# For installing from the extracted package tmp directory
pkg_install() {
    # remove the versioned folder, just in case it's there with junk
    rm -rf "$pkg_src_bin"
    mkdir -p "$pkg_src_bin"

    # rename the entire extracted folder to the new location
    # (this will be "$HOME/.local/opt/xmpl-v$WEBI_VERSION" by default)
    mv ./"$pkg_cmd_name"* "$pkg_src_cmd"
}
