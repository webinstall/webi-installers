# title: Caddy
# homepage: https://github.com/caddyserver/caddy
# tagline: Fast, multi-platform web server with automatic HTTPS
# description: |
#   Caddy is an extensible server platform that uses TLS by default.
# examples: |
#   ```bash
#   caddy start
#   ```

set -e
set -u

pkg_cmd_name="caddy"
pkg_dst="$HOME/.local"

# the "source" here isn't used, nor very meaningful,
# but we'll use the download location as a junk value
pkg_src="$HOME/Downloads/$WEBI_PKG_FILE"

pkg_get_current_version() {
    # 'caddy version' has output in this format:
    #       v2.1.0 h1:pQSaIJGFluFvu8KDGDODV8u4/QRED/OPyIR+MWYYse8=
    # This trims it down to just the version number:
    #       2.0.0
    echo "$(caddy version 2>/dev/null | head -n 1 | cut -d' ' -f1 | sed 's:^v::')"
}

pkg_format_cmd_version() {
    # 'caddy v2.1.0' is the canonical version format for caddy
    my_version="$1"
    echo "$pkg_cmd_name v$my_version"
}

pkg_link_src_dst() {
    # caddy is just a single file, no directory linking to do
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

        # ensure the bin dir exists
        mkdir -p "$pkg_dst_bin"

        # rename the entire extracted folder to the new location
        # (this will be "$HOME/.local/bin/caddy", as set above)

        # ex (full directory): ./node-v13-linux-amd64/bin/node.exe
        #mv ./"$pkg_cmd_name"* "$pkg_src"

        # ex (single file): ./caddy-v2.0.0-linux-amd64.exe
        mv ./"$pkg_cmd_name"* "$pkg_dst_cmd"
        chmod a+x "$pkg_dst_cmd"

        # ex (single file, nested in directory): ./rg/rg-v13-linux-amd64
        #mv ./"$pkg_cmd_name"*/"$pkg_cmd_name"* "$pkg_commend_cmd"
        #chmod a+x "$pkg_dst_cmd"

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
    echo "Installed 'caddy' v$WEBI_VERSION as $pkg_dst_cmd"
}
