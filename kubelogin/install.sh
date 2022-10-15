#!/bin/sh

# shellcheck disable=SC2034
# "'pkg_cmd_name' appears unused. Verify it or export it."

__init_kubelogin() {
    set -e
    set -u

    #####################
    # Install kubelogin #
    #####################

    # Every package should define these 6 variables
    pkg_cmd_name="kubelogin"

    pkg_dst_cmd="$HOME/.local/bin/kubelogin"
    pkg_dst="$pkg_dst_cmd"

    pkg_src_cmd="$HOME/.local/opt/kubelogin-v$WEBI_VERSION/bin/kubelogin"
    pkg_src_dir="$HOME/.local/opt/kubelogin-v$WEBI_VERSION"
    pkg_src="$pkg_src_cmd"

    # pkg_install must be defined by every package
    pkg_install() {
        # ~/.local/opt/kubelogin-v0.99.9/bin
        mkdir -p "$(dirname "${pkg_src_cmd}")"

        # mv ./kubelogin-*/kubelogin ~/.local/opt/kubelogin-v0.99.9/bin/kubelogin
        mv ./bin/*/kubelogin "${pkg_src_cmd}"
    }

    # pkg_get_current_version is recommended, but not required
    pkg_get_current_version() {
        # 'kubelogin --version' has output in this format:
        #       kubelogin version
        #       git hash: v0.0.20/872ed59b23e06c3a0eb950cb67e7bd2b0e9d48d7
        #       Go version: go1.18.5
        #       Build time: 2022-08-09T18:30:45Z
        #       Platform: linux/amd64
        # This trims it down to just the version number:
        #       0.0.20
        kubelogin --version 2> /dev/null |
            head -n 2 |
            tail -n 1 |
            cut -d ' ' -f 3 |
            cut -d '/' -f 1 |
            cut -d 'v' -f 2
    }

}

__init_kubelogin
