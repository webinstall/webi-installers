#!/bin/sh

__init_shellcheck() {
    set -e
    set -u

    ######################
    # Install shellcheck #
    ######################

    # Every package should define these 6 variables
    pkg_cmd_name="shellcheck"

    pkg_dst_cmd="$HOME/.local/bin/shellcheck"
    pkg_dst="$pkg_dst_cmd"

    pkg_src_cmd="$HOME/.local/opt/shellcheck-v$WEBI_VERSION/bin/shellcheck"
    pkg_src_dir="$HOME/.local/opt/shellcheck-v$WEBI_VERSION"
    pkg_src="$pkg_src_cmd"

    # pkg_install must be defined by every package
    pkg_install() {
        # ~/.local/opt/shellcheck-v0.99.9/bin
        mkdir -p "$(dirname "$pkg_src_cmd")"

        # mv ./shellcheck-*/shellcheck ~/.local/opt/shellcheck-v0.99.9/bin/shellcheck
        mv ./shellcheck-*/shellcheck "$pkg_src_cmd"
    }

    # pkg_get_current_version is recommended, but (soon) not required
    pkg_get_current_version() {
        # 'shellcheck --version' has output in this format:
        #       ShellCheck - shell script analysis tool
        #       version: 0.7.1
        #       license: GNU General Public License, version 3
        #       website: https://www.shellcheck.net

        # This trims it down to just the version number:
        #       0.7.1
        shellcheck --version 2> /dev/null | head -n 2 | tail -n 1 | cut -d' ' -f 2
    }

}

__init_shellcheck
