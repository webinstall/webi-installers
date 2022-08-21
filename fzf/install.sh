#!/bin/sh
set -e
set -u

__init_fzf() {

    ###############
    # Install fzf #
    ###############

    WEBI_SINGLE=true

    pkg_get_current_version() {
        # 'fzf --version' has output in this format:
        #       0.21.1 (334a4fa)
        # This trims it down to just the version number:
        #       0.21.1
        fzf --version 2> /dev/null | head -n 1 | cut -d' ' -f 1
    }

    pkg_install() {
        # $HOME/.local/bin
        mkdir -p "$pkg_src_bin"

        # mv ./fzf* "$HOME/.local/opt/fzf-v0.21.1/bin/fzf"
        mv ./fzf* "$pkg_src_cmd"

        # chmod a+x "$HOME/.local/opt/fzf-v0.21.1/bin/fzf"
        chmod a+x "$pkg_src_cmd"
    }
}

__init_fzf
