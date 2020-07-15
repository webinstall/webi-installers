{
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
        # ~/.local/opt/rg-v11.1.0/bin
        mkdir -p "$pkg_src_bin"

        # mv ./ripgrep-*/rg ~/.local/opt/rg-v11.1.0/bin/rg
        mv ./ripgrep-*/rg "$pkg_src_cmd"

        # chmod a+x ~/.local/opt/rg-v11.1.0/bin/rg
        chmod a+x "$pkg_src_cmd"
    }
}
