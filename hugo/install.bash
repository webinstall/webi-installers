# title: Hugo
# homepage: https://github.com/gohugoio/hugo
# tagline: The world’s fastest framework for building websites
# description: |
#   Hugo is one of the most popular open-source static site generators. With its amazing speed and flexibility, Hugo makes building websites fun again.
# examples: |
#   ```bash
#   hugo
#   ```
#
#   ```bash
#   hugo server -D
#   ```

set -e
set -u

pkg_cmd_name="hugo"
pkg_common_opt="$HOME/.local"

# just a junk file so that the version check always fails for non-current versions
pkg_new_opt="$HOME/.local/opt/hugo-doesntexist111"

pkg_get_current_version() {
    # 'hugo version' has output in this format:
    #       Hugo Static Site Generator v0.72.0-8A7EF3CF darwin/amd64 BuildDate: 2020-05-31T12:07:44Z
    # This trims it down to just the version number:
    #       0.72.0
    echo "$(hugo version 2>/dev/null | head -n 1 | cut -d' ' -f5 | cut -d '-' -f1 | sed 's:^v::')"
}

pkg_format_cmd_version() {
    # 'node v12.8.0' is the canonical version format for node
    my_version="$1"
    echo "$pkg_cmd_name v$my_version"
}

pkg_link_new_version() {
    # hugo is just a single file, no directory linking to do
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
        # (this will be "$HOME/.local/opt/node-v$WEBI_VERSION" by default)
        mkdir -p "$pkg_common_bin"
        mv ./"$pkg_cmd_name"* "$pkg_common_cmd"

    popd 2>&1 >/dev/null
}

pkg_post_install() {
    # just in case we add something in the future
    pkg_link_new_version

    # web_path_add is defined in webi/template.bash at https://github.com/webinstall/packages
    # Adds "$HOME/.local/opt/node" to PATH
    webi_path_add "$pkg_common_bin"
}
