#!/bin/sh
# shellcheck disable=SC2034
# "'pkg_cmd_name' appears unused. Verify it or export it."

set -e
set -u

__init_reactorcide() {

    #######################
    # Install reactorcide #
    #######################

    WEBI_SINGLE=true

    # Every package should define these 6 variables
    pkg_cmd_name="reactorcide"

    # pkg_get_current_version is recommended, but not required
    pkg_get_current_version() {
        # 'reactorcide --version' has output in this format:
        #       reactorcide 1.2.3
        # This trims it down to just the version number:
        #       1.2.3
        reactorcide --version 2> /dev/null | head -n 1 | cut -d' ' -f 2
    }

    # pkg_install must be defined by every package
    pkg_install() {
        # ~/.local/opt/reactorcide-v0.12.0/bin
        mkdir -p "$(dirname "$pkg_src_cmd")"

        # the archive contains a single bare binary at its root:
        #     reactorcide-0.12.0-linux-amd64.tar.gz -> ./reactorcide
        if test -f ./reactorcide; then
            # mv ./reactorcide ~/.local/opt/reactorcide-v0.12.0/bin/reactorcide
            mv ./reactorcide "$pkg_src_cmd"
        elif test -e ./reactorcide-*/reactorcide; then
            mv ./reactorcide-*/reactorcide "$pkg_src_cmd"
        else
            echo >&2 "failed to find 'reactorcide' executable"
            return 1
        fi
    }

}

__init_reactorcide
