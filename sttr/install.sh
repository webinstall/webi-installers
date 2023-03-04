#!/bin/sh
set -e
set -u

__init_sttr() {

    ######################
    # Install sttr #
    ######################

    # Every package should define these 6 variables
    pkg_cmd_name="sttr"

    pkg_dst_cmd="$HOME/.local/bin/sttr"
    pkg_dst="$pkg_dst_cmd"

    pkg_src_cmd="$HOME/.local/opt/sttr-v$WEBI_VERSION/bin/sttr"
    pkg_src_dir="$HOME/.local/opt/sttr-v$WEBI_VERSION"
    pkg_src="$pkg_src_cmd"

    # pkg_install must be defined by every package
    pkg_install() {
        # ~/.local/opt/sttr-v0.99.9/bin
        mkdir -p "$(dirname "$pkg_src_cmd")"

        # mv ./sttr-*/sttr ~/.local/opt/sttr-v0.99.9/bin/sttr
        mv ./sttr "$pkg_src_cmd"
    }

    # pkg_get_current_version is recommended, but (soon) not required
    pkg_get_current_version() {
        # 'sttr --version' has output in this format:
        #       sttr 0.99.9 (rev abcdef0123)
        # This trims it down to just the version number:
        #       0.99.9
        sttr version 2> /dev/null | head -n 1 | cut -d ' ' -f 2
    }

}

__init_sttr
