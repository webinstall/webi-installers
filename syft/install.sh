#!/bin/sh
set -e
set -u

__init_syft() {

    ################
    # Install Syft #
    ################

    # Every package should define these 6 variables
    pkg_cmd_name="syft"

    pkg_dst_cmd="$HOME/.local/bin/syft"
    pkg_dst="$pkg_dst_cmd"

    pkg_src_cmd="$HOME/.local/opt/syft-v$WEBI_VERSION/bin/syft"
    pkg_src_dir="$HOME/.local/opt/syft-v$WEBI_VERSION"
    pkg_src="$pkg_src_cmd"

    # pkg_install must be defined by every package
    pkg_install() {
        # ~/.local/opt/syft-v0.101.1/bin
        mkdir -p "$(dirname "${pkg_src_cmd}")"

        # mv ./syft ~/.local/opt/syft-v0.101.1/bin/syft
        mv ./"$pkg_cmd_name"* "$pkg_src"
    }

    # pkg_get_current_version is recommended, but not required
    pkg_get_current_version() {
        # 'syft --version' has output in this format:
        #       syft 0.101.1
        # This trims it down to just the version number:
        #       0.101.1
        syft --version 2> /dev/null |
            head -n 1 |
            cut -d ' ' -f 2
    }

}

__init_syft
