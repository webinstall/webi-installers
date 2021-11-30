#!/bin/bash
set -euo pipefail

# function __install_make_workflows_sh() {
#     pkg_cmd_name="make-workflows.sh"
#     pkg_dst_cmd="$HOME/.local/bin/$pkg_cmd_name"
#     curl -LsSf \
#         'https://raw.githubusercontent.com/kuvaldini/make-workflows.sh/main/make-workflows.sh' \
#         >"$pkg_dst_cmd" \
#     && chmod +x "$pkg_dst_cmd"
# }
# __install_make_workflows_sh


function __init_make_workflows_sh() {

    # Every package should define these 6 variables
    pkg_cmd_name="make-workflows.sh"
    pkg_dst_cmd="$HOME/.local/bin/$pkg_cmd_name"
    pkg_dst="$pkg_dst_cmd"
    pkg_src_dir="$HOME/.local/opt/$pkg_cmd_name-v$WEBI_VERSION"
    pkg_src_cmd="$HOME/.local/opt/$pkg_cmd_name-v$WEBI_VERSION/bin/$pkg_cmd_name"
    pkg_src="$pkg_src_cmd"

    # pkg_install must be defined by every package
    pkg_install() {
        # ~/.local/opt/PACKAGE-v0.99.9/bin
        mkdir -p "$(dirname "$pkg_src_cmd")"
        # mv ./delta-*/delta ~/.local/opt/delta-v0.99.9/bin/delta
        mv ./$pkg_cmd_name-*/$pkg_cmd_name "$pkg_src_cmd"
    }

    # pkg_get_current_version is recommended, but not required
    pkg_get_current_version() {
        # 'make-workflows.sh --version' has output in this format:
        #       make-workflows.sh 1.0.0
        # This trims it down to just the version number:
        #       1.0.0
        make-workflows.sh --version 2> /dev/null |
            head -n 1 |
            cut -d ' ' -f 2
    }

}

__init_make_workflows_sh
