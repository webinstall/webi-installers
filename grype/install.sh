#!/bin/sh
set -e
set -u

__init_grype() {

    ##################
    # Install Grype  #
    ##################

    # Every package should define these 6 variables
    pkg_cmd_name="grype"

    pkg_dst_cmd="$HOME/.local/bin/grype"
    pkg_dst="$pkg_dst_cmd"

    pkg_src_cmd="$HOME/.local/opt/grype-v$WEBI_VERSION/bin/grype"
    pkg_src_dir="$HOME/.local/opt/grype-v$WEBI_VERSION"
    pkg_src="$pkg_src_cmd"

    # pkg_install must be defined by every package
    pkg_install() {
        # ~/.local/opt/grype-v0.99.9/bin
        mkdir -p "$(dirname "${pkg_src_cmd}")"

        # mv ./grype ~/.local/opt/grype-v0.99.9/bin/grype
        mv ./"$pkg_cmd_name"* "$pkg_src"
    }

    # pkg_get_current_version is recommended, but not required
    pkg_get_current_version() {
        # 'grype --version' has output in this format:
        #       grype 0.70.0
        # This trims it down to just the version number:
        #       0.70.0
        grype --version 2> /dev/null |
            head -n 1 |
            cut -d ' ' -f 2
    }

}

__init_grype
