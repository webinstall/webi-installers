set -e
set -u

###################
# Install ripgrep #
###################

new_rg="${HOME}/.local/bin/rg"
WEBI_SINGLE=true

pkg_get_current_version() {
  echo $(rg --version 2>/dev/null | head -n 1 | cut -d ' ' -f 2)
}

pkg_install() {
    # $HOME/.local/xbin
    mkdir -p "$pkg_src_bin"

    # mv ./ripgrep-*/rg "$HOME/.local/xbin/rg-v11.1.0"
    mv ./ripgrep-*/rg "$pkg_src_cmd"

    # chmod a+x "$HOME/.local/xbin/rg-v11.1.0"
    chmod a+x "$pkg_src_cmd"
}
