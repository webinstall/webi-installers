#!/bin/bash

{
    set -e
    set -u

    ##################
    # Install curlie #
    ##################

    WEBI_SINGLE=true

    pkg_get_current_version() {
      # 'curlie --version' has output in this format:
      #       curlie 0.15.4
      # This trims it down to just the version number:
      #       0.15.4
      echo $(curlie --version 2>/dev/null | head -n 1 | cut -d' ' -f 2)
    }

    pkg_install() {
        # $HOME/.local/xbin
        mkdir -p "$pkg_src_bin"

        # mv ./curlie* "$HOME/.local/opt/curlie-v0.15.4/bin/curlie"
        mv ./curlie* "$pkg_src_cmd"

        # chmod a+x "$HOME/.local/xbin/rg-v11.1.0"
        chmod a+x "$pkg_src_cmd"
    }
}
