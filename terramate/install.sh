#!/bin/sh
set -e
set -u

__init_terramate() {

    #####################
    # Install terramate #
    #####################

    # Every package should define these 6 variables
    pkg_cmd_name="terramate"

    pkg_dst_cmd="$HOME/.local/bin/terramate"
    pkg_dst="$pkg_dst_cmd"

    pkg_src_cmd="$HOME/.local/opt/terramate-v$WEBI_VERSION/bin/terramate"
    pkg_src_dir="$HOME/.local/opt/terramate-v$WEBI_VERSION"
    pkg_src="$pkg_src_cmd"

    # pkg_install must be defined by every package
    pkg_install() {
        # ~/.local/opt/terramate-v0.11.4/bin
        mkdir -p "$(dirname "$pkg_src_cmd")"

        # mv ./terramate* ~/.local/opt/terramate-v0.11.4/bin/terramate
        mv terramate* "$pkg_src_cmd"
    }

    # pkg_get_current_version is recommended, but (soon) not required
    pkg_get_current_version() {
        # 'terramate version' has output in this format:

        # 0.11.3
        #
        # Your version of Terramate is out of date! The latest version
        # is 0.11.4 (released on Tue Dec  3 19:27:35 UTC 2024).
        # You can update by downloading from https://github.com/terramate-io/terramate/releases/tag/v0.11.4

        # This trims it down to just the version number:
        # 0.11.4
        terramate version | head -n 1 | cut -d' ' -f1
    }

}

__init_terramate
