#!/bin/bash
# shellcheck disable=SC2154

function __init_gitdeploy() {
    set -e
    set -u

    #####################
    # Install gitdeploy #
    #####################

    # Every package should define these 6 variables
    export pkg_cmd_name="gitdeploy"

    export pkg_dst_cmd="$HOME/.local/bin/gitdeploy"
    export pkg_dst="$pkg_dst_cmd"

    export pkg_src_cmd="$HOME/.local/opt/gitdeploy-v$WEBI_VERSION/bin/gitdeploy"
    export pkg_src_dir="$HOME/.local/opt/gitdeploy-v$WEBI_VERSION"
    export pkg_src="$pkg_src_cmd"

    pkg_install() {
        # $HOME/.local/opt/gitdeploy-v0.7.1/bin
        mkdir -p "$pkg_src_bin"

        # mv ./gitdeploy* "$HOME/.local/opt/gitdeploy-v0.7.1/bin/gitdeploy"
        mv ./"$pkg_cmd_name"* "$pkg_src_cmd"

        # chmod a+x "$HOME/.local/opt/gitdeploy-v0.7.1/bin/gitdeploy"
        chmod a+x "$pkg_src_cmd"
    }

    pkg_get_current_version() {
        # 'gitdeploy version' has output in this format:
        #       gitdeploy v0.7.1 (be68fec) 2020-10-20T22:27:47Z)
        # This trims it down to just the version number:
        #       0.7.1
        gitdeploy --version 2> /dev/null | head -n 1 | cut -d' ' -f2 | sed 's:^v::'
    }

}

__init_gitdeploy
