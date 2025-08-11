#!/bin/sh
set -e
set -u

__init_tlrc() {

    ###############
    # Install tlrc #
    ###############

    # Every package should define these 6 variables
    pkg_cmd_name="tlrc"

    pkg_dst_cmd="$HOME/.local/bin/tlrc"
    pkg_dst="$pkg_dst_cmd"

    pkg_src_cmd="$HOME/.local/opt/tlrc-v$WEBI_VERSION/tlrc"
    pkg_src_dir="$HOME/.local/opt/tlrc-v$WEBI_VERSION"
    pkg_src="$pkg_src_cmd"

    # pkg_install must be defined by every package
    pkg_install() {
        # ~/.local/opt/tlrc-v1.11.1/
        mkdir -p "$(dirname "${pkg_src_cmd}")"

        # mv ./tlrc ~/.local/opt/tlrc-v1.11.1/tlrc
        mv ./tlrc "${pkg_src_cmd}"
    }

    # pkg_get_current_version is recommended, but not required
    pkg_get_current_version() {
        # 'tlrc --version' has output in this format:
        #       tlrc 1.11.1
        # This trims it down to just the version number:
        #       1.11.1
        tlrc --version 2> /dev/null |
            head -n 1 |
            cut -d ' ' -f 2
    }

}

__init_tlrc
