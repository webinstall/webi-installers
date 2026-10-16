#!/bin/sh

__init_lazygit() {
    set -e
    set -u

    ###################
    # Install lazygit #
    ###################

    # Every package should define these 6 variables
    pkg_cmd_name="lazygit"

    pkg_dst_cmd="$HOME/.local/bin/lazygit"
    pkg_dst="$pkg_dst_cmd"

    pkg_src_cmd="$HOME/.local/opt/lazygit-v$WEBI_VERSION/bin/lazygit"
    pkg_src_dir="$HOME/.local/opt/lazygit-v$WEBI_VERSION"
    pkg_src="$pkg_src_cmd"

    # pkg_install must be defined by every package
    pkg_install() {
        # ~/.local/opt/gh-v0.99.9/bin
        mkdir -p "$(dirname "$pkg_src_cmd")"

        # mv ./lazygit-*/lazygit ~/.local/opt/lazygit-v0.99.9/bin/lazygit
        mv ./lazygit "$pkg_src_cmd"
    }

    # pkg_get_current_version is recommended, but (soon) not required
    pkg_get_current_version() {
        # 'lazygit --version' has output in this format:
        #       commit=, build date=, build source=nix, version=0.44.1, os=linux, arch=amd64, git version=2.47.0
        # This trims it down to just the version number:
        #       0.44.1
        output=$(lazygit --version)
        version=${output#*version=}
        version=${version%%,*}
        echo "$version"
    }

}

__init_lazygit
