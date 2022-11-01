#!/bin/bash

# shellcheck disable=SC2034
# "'pkg_cmd_name' appears unused. Verify it or export it."

function __init_eksctl() {
    set -e
    set -u

    ##################
    # Install eksctl #
    ##################

    # Every package should define these 6 variables
    pkg_cmd_name="eksctl"

    pkg_dst_cmd="$HOME/.local/bin/eksctl"
    pkg_dst="$pkg_dst_cmd"

    pkg_src_cmd="$HOME/.local/opt/eksctl-v$WEBI_VERSION/bin/eksctl"
    pkg_src_dir="$HOME/.local/opt/eksctl-v$WEBI_VERSION"
    pkg_src="$pkg_src_cmd"

    # pkg_install must be defined by every package
    pkg_install() {
        # ~/.local/opt/eksctl-v0.99.9/bin
        mkdir -p "$(dirname "${pkg_src_cmd}")"

        # mv ./eksctl-*/eksctl ~/.local/opt/eksctl-v0.99.9/bin/eksctl
        mv ./eksctl "${pkg_src_cmd}"
    }

    # pkg_get_current_version is recommended, but not required
    pkg_get_current_version() {
        # 'eksctl --version' has output in this format:
        #       eksctl 0.99.9 (rev abcdef0123)
        # This trims it down to just the version number:
        #       0.99.9
        eksctl --version 2> /dev/null |
            head -n 1 |
            cut -d ' ' -f 2
    }

}

__init_eksctl
