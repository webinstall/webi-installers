# title: Gitea
# homepage: https://github.com/go-gitea/gitea
# tagline: Git with a cup of tea, painless self-hosted git service 
# description: |
#   `gitea` is a clean, lightweight self-hosted Github alternative, forked from Gogs. Lighter and more user-friendly than Gitlab.
# examples: |
#   ```bash
#   gitea --version
#   ```

set -e
set -u

pkg_cmd_name="gitea"
pkg_dst="$HOME/.local"

# pkg_src isn't used in this script,
# just setting a junk value for completeness (and possibly debug output)
pkg_src="$HOME/Downloads/$WEBI_PKG_FILE"

pkg_get_current_version() {
    # 'gitea version' has output in this format:
    #       v2.1.0 h1:pQSaIJGFluFvu8KDGDODV8u4/QRED/OPyIR+MWYYse8=
    # This trims it down to just the version number:
    #       2.0.0
    echo "$(gitea --version 2>/dev/null | head -n 1 | cut -d' ' -f3)"
}

pkg_format_cmd_version() {
    # 'gitea v2.1.0' is the canonical version format for gitea
    my_version="$1"
    echo "$pkg_cmd_name v$my_version"
}

pkg_link_src_dst() {
    # gitea is just a single file, no directory linking to do
    true
}

pkg_pre_install() {
    # if selected version is installed, quit
    webi_check
    # will save to ~/Downloads/$WEBI_PKG_FILE by default
    webi_download
    # supported formats (.xz, .tar.*, .zip) will be extracted to $WEBI_TMP
    webi_extract
}

pkg_install() {
    pushd "$WEBI_TMP" 2>&1 >/dev/null

        # rename the entire extracted folder to the new location
        # (this will be "$HOME/.local/bin/gitea" by default)
        mkdir -p "$pkg_dst_bin"
        mv ./"$pkg_cmd_name"* "$pkg_dst_cmd"
        chmod a+x "$pkg_dst_cmd"

    popd 2>&1 >/dev/null
}

pkg_post_install() {
    # just in case we add something in the future
    pkg_link_src_dst

    # web_path_add is defined in webi/template.bash at https://github.com/webinstall/packages
    # Adds "$HOME/.local/bin" to PATH
    webi_path_add "$pkg_dst_bin"
}

pkg_post_install_message() {
    echo "Installed 'gitea' v$WEBI_VERSION as $pkg_dst_cmd"
}
