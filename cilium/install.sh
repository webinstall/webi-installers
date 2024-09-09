#!/bin/sh

__init_cilium() {
    set -e
    set -u

    ##################
    # Install cilium #
    ##################

    pkg_cmd_name="cilium"

    pkg_dst_cmd="$HOME/.local/bin/cilium"
    pkg_dst="$pkg_dst_cmd"

    pkg_src_cmd="$HOME/.local/opt/cilium-v$WEBI_VERSION/bin/cilium"
    pkg_src_dir="$HOME/.local/opt/cilium-v$WEBI_VERSION"
    pkg_src="$pkg_src_cmd"

    WEBI_SINGLE=true

    # pkg_install must be defined by every package
    pkg_install() {
        # ~/.local/opt/cilium-v0.16.16/bin
        mkdir -p "$(dirname "${pkg_src_cmd}")"

        # mv ./hugo ~/.local/opt/cilium-v0.16.16/bin/
        mv ./cilium "${pkg_src_cmd}"
    }

    pkg_get_current_version() {
        cilium version 2> /dev/null |
            head -n 1 |
            cut -d ' ' -f 2
    }

}

__init_cilium
