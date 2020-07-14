#!/bin/bash

{
    set -e
    set -u

    ###############
    # Install hexyl #
    ###############

    WEBI_SINGLE=true

    pkg_get_current_version() {
      # 'hexyl --version' has output in this format:
      #       hexyl 0.8.0
      # This trims it down to just the version number:
      #       0.8.0
      echo $(hexyl --version 2>/dev/null | head -n 1 | cut -d' ' -f 2)
    }

    pkg_install() {
        # $HOME/.local/
        mkdir -p "$pkg_src_bin"

        # mv ./hexyl-*/hexyl "$HOME/.local/opt/hexyl-v0.8.0/bin/hexyl"
        mv ./hexyl-*/hexyl "$pkg_src_cmd"

        # chmod a+x "$HOME/.local/xbin/rg-v11.1.0"
        chmod a+x "$pkg_src_cmd"
    }
}
