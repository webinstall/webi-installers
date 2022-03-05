#!/bin/bash

# shellcheck disable=SC2034
# "'pkg_cmd_name' appears unused. Verify it or export it."

function __init_dashcore() {
    set -e
    set -u

    ##################
    # Install dashcore #
    ##################

    # Every package should define these 6 variables
    pkg_cmd_name="dashd"

    pkg_dst_cmd="$HOME/.local/opt/dashcore/bin/dashd"
    pkg_dst_dir="$HOME/.local/opt/dashcore"
    pkg_dst="$pkg_dst_dir"

    pkg_src_cmd="$HOME/.local/opt/dashcore-v$WEBI_VERSION/bin/dashd"
    pkg_src_dir="$HOME/.local/opt/dashcore-v$WEBI_VERSION"
    pkg_src="$pkg_src_dir"

    # pkg_install must be defined by every package
    pkg_install() {
        # mv ./dashcore-* ~/.local/opt/dashcore-v0.17.0
        mv ./dashcore-* "${pkg_src_dir}"
    }

    # pkg_get_current_version is recommended, but not required
    pkg_get_current_version() {
        # 'dashd --version' has output in this format:
        #       Dash Core Daemon version v0.17.0.3
        # This trims it down to just the version number:
        #       0.17.0
        dashd --version 2> /dev/null |
            head -n 1 |
            cut -d ' ' -f 5 |
            sed 's:^v::'
    }

}

__init_dashcore
