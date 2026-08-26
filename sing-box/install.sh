#!/bin/sh

# shellcheck disable=SC2034
# "'pkg_cmd_name' appears unused. Verify it or export it."

__init_sing_box() {
    set -e
    set -u

    ##################
    # Install sing-box #
    ##################

    # Every package should define these 6 variables
    pkg_cmd_name="sing-box"

    pkg_dst_cmd="$HOME/.local/bin/sing-box"
    pkg_dst="$pkg_dst_cmd"

    pkg_src_cmd="$HOME/.local/opt/sing-box-v$WEBI_VERSION/bin/sing-box"
    pkg_src_dir="$HOME/.local/opt/sing-box-v$WEBI_VERSION"
    pkg_src="$pkg_src_cmd"

    # pkg_install must be defined by every package
    pkg_install() {
        # ~/.local/opt/sing-box-v0.99.9/bin
        mkdir -p "$(dirname "${pkg_src_cmd}")"

        # mv ./sing-box-*/sing-box ~/.local/opt/sing-box-v0.99.9/bin/sing-box
        mv ./sing-box-*/sing-box "${pkg_src_cmd}"
    }

    # pkg_get_current_version is recommended, but not required
    pkg_get_current_version() {
        # 'sing-box --version' has output in this format:
        #       sing-box 0.99.9 (rev abcdef0123)
        # This trims it down to just the version number:
        #       0.99.9
        sing-box --version 2> /dev/null |
            head -n 1 |
            cut -d ' ' -f 2
    }

}

__init_sing_box
