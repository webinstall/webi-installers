#!/bin/bash
set -e
set -u

function __init_nvim() {

    ###################
    # Install neovim #
    ###################

    # Every package should define these 6 variables
    pkg_cmd_name="nvim"

    pkg_dst_cmd="$HOME/.local/bin/nvim"
    pkg_dst="$pkg_dst_cmd"

    pkg_src_cmd="$HOME/.local/opt/nvim-v$WEBI_VERSION/bin/nvim"
    pkg_src_dir="$HOME/.local/opt/nvim-v$WEBI_VERSION"
    pkg_src="$pkg_src_cmd"

    # pkg_install must be defined by every package
    pkg_install() {
        # ~/.local/opt/nvim-v12.1.1/bin
        mkdir -p "$(dirname $pkg_src_cmd)"

        # mv ./nvim-*/bin/nvim ~/.local/opt/neovim-v12.1.1/bin/nvim
        mv ./nvim-*/bin/nvim "$pkg_src_cmd"
    }

    # pkg_get_current_version is recommended, but (soon) not required
    pkg_get_current_version() {
        # 'nvim --version' has output in this format:
        #       NVIM v0.6.1
        #       <MORE INFO>
        # This trims it down to just the version number:
        #       0.6.1
        echo $(nvim --version 2> /dev/null | head -n 1 | cut -d ' ' -f 2 | cut -c 2-)
    }
}

__init_nvim
