#!/bin/sh

# shellcheck disable=SC2034
# "'pkg_cmd_name' appears unused. Verify it or export it."

__init_ffuf() {
    set -e
    set -u

    ################
    # Install ffuf #
    ################

    # Every package should define these 6 variables
    pkg_cmd_name="ffuf"

    pkg_dst_cmd="$HOME/.local/bin/ffuf"
    pkg_dst="$pkg_dst_cmd"

    pkg_src_cmd="$HOME/.local/opt/ffuf-v$WEBI_VERSION/bin/ffuf"
    pkg_src_dir="$HOME/.local/opt/ffuf-v$WEBI_VERSION"
    pkg_src="$pkg_src_cmd"

    # pkg_install must be defined by every package
    pkg_install() {
        # ~/.local/opt/ffuf-v2.1.0/bin
        mkdir -p "$(dirname "${pkg_src_cmd}")"

        # mv ./ffuf-*/ffuf ~/.local/opt/ffuf-v2.1.0/bin/ffuf
        mv ./ffuf "$pkg_src_cmd"
    }

    # pkg_get_current_version is recommended, but not required
    pkg_get_current_version() {
        # 'ffuf -V' has output in this format:
        #       ffuf version: 2.1.0
        # This trims it down to just the version number:
        #       2.1.0
        ffuf -V 2> /dev/null |
            head -n 1 |
            cut -d' ' -f3
    }

}

__init_ffuf
