#!/bin/sh

# shellcheck disable=SC2034
# "'pkg_cmd_name' appears unused. Verify it or export it."

__init_xsv() {
    set -e
    set -u

    ##################
    # Install xsv #
    ##################

    # Every package should define these 6 variables
    pkg_cmd_name="xsv"

    pkg_dst_cmd="$HOME/.local/bin/xsv"
    pkg_dst="$pkg_dst_cmd"

    pkg_src_cmd="$HOME/.local/opt/xsv-v$WEBI_VERSION/bin/xsv"
    pkg_src_dir="$HOME/.local/opt/xsv-v$WEBI_VERSION"
    pkg_src="$pkg_src_cmd"

    # pkg_install must be defined by every package
    pkg_install() {
        # ~/.local/opt/xsv-v0.99.9/bin
        mkdir -p "$(dirname "${pkg_src_cmd}")"

        # mv ./xsv-*/xsv ~/.local/opt/xsv-v0.99.9/bin/xsv
        mv ./xsv "${pkg_src_cmd}"
    }

    # pkg_get_current_version is recommended, but not required
    pkg_get_current_version() {
        # 'xsv --version' has output in this format:
        #       xsv 0.99.9 (rev abcdef0123)
        # This trims it down to just the version number:
        #       0.99.9
        xsv --version 2> /dev/null |
            head -n 1 |
            cut -d ' ' -f 2
    }

}

__init_xsv
