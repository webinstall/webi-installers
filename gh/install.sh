#!/bin/sh

__init_gh() {
    set -e
    set -u

    ##############
    # Install gh #
    ##############

    # Every package should define these 6 variables
    pkg_cmd_name="gh"

    pkg_dst_cmd="$HOME/.local/bin/gh"
    pkg_dst="$pkg_dst_cmd"

    pkg_src_cmd="$HOME/.local/opt/gh-v$WEBI_VERSION/bin/gh"
    pkg_src_dir="$HOME/.local/opt/gh-v$WEBI_VERSION"
    pkg_src="$pkg_src_cmd"

    # pkg_install must be defined by every package
    pkg_install() {
        # ~/.local/opt/gh-v0.99.9/bin
        mkdir -p "$(dirname "$pkg_src_cmd")"

        # mv ./gh-*/gh ~/.local/opt/gh-v0.99.9/bin/gh
        mv ./"$pkg_cmd_name"*/bin/gh "$pkg_src_cmd"
    }

    # pkg_get_current_version is recommended, but (soon) not required
    pkg_get_current_version() {
        # 'gh --version' has output in this format:
        #       gh 0.99.9 (rev abcdef0123)
        # This trims it down to just the version number:
        #       0.99.9
        gh --version 2> /dev/null | head -n 1 | cut -d ' ' -f 2
    }

}

__init_gh
