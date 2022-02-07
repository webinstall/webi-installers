#!/bin/bash

function __init_notion-md-gen() {
    set -e
    set -u

    ####################
    # Install notion-md-gen #
    ####################

    # Every package should define these 6 variables
    pkg_cmd_name="notion-md-gen"

    pkg_dst_cmd="$HOME/.local/bin/notion-md-gen"
    pkg_dst="$pkg_dst_cmd"

    pkg_src_cmd="$HOME/.local/opt/notion-md-gen-v$WEBI_VERSION/bin/notion-md-gen"
    pkg_src_dir="$HOME/.local/opt/notion-md-gen-v$WEBI_VERSION"
    pkg_src="$pkg_src_cmd"

    pkg_install() {
        # $HOME/.local/opt/notion-md-gen-v1.0.0/bin
        mkdir -p "$(dirname $pkg_src_cmd)"

        # mv ./notion-md-gen* "$HOME/.local/opt/notion-md-gen-v1.0.0/bin/notion-md-gen"
        mv ./"$pkg_cmd_name"* "$pkg_src_cmd"

        # chmod a+x "$HOME/.local/opt/notion-md-gen-v1.0.0/bin/notion-md-gen"
        chmod a+x "$pkg_src_cmd"
    }

    pkg_get_current_version() {
        # 'notion-md-gen version' has output in this format:
        #       release: 1.0.0, repo: https://github.com/bonaysoft/notion-md-gen.git
        # This trims it down to just the version number:
        #       1.0.0
        echo "echo $(notion-md-gen version 2> /dev/null | head -n 1 | cut -d',' -f1 | cut -d' ' -f2)"
    }

}

__init_notion-md-gen
