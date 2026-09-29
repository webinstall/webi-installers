#!/bin/sh
# shellcheck disable=SC2034
# "'pkg_cmd_name' appears unused. Verify it or export it."

set -e
set -u

__init_foundry() {

    ###################
    # Install foundry #
    ###################

    WEBI_SINGLE=true

    # Every package should define these 6 variables
    pkg_cmd_name="foundry"

    # pkg_get_current_version is recommended, but not required
    pkg_get_current_version() {
        # 'foundry --version' has output in this format:
        #       foundry version 0.7.5
        # This trims it down to just the version number:
        #       0.7.5
        foundry --version 2> /dev/null | head -n 1 | cut -d' ' -f 3
    }

    # pkg_install must be defined by every package
    pkg_install() {
        # ~/.local/opt/foundry-v0.7.5/bin
        mkdir -p "$(dirname "$pkg_src_cmd")"

        # the archive contains a single bare binary at its root:
        #     foundry-0.7.5-linux-amd64.tar.gz -> ./foundry
        if test -f ./foundry; then
            # mv ./foundry ~/.local/opt/foundry-v0.7.5/bin/foundry
            mv ./foundry "$pkg_src_cmd"
        elif test -e ./foundry-*/foundry; then
            mv ./foundry-*/foundry "$pkg_src_cmd"
        else
            echo >&2 "failed to find 'foundry' executable"
            return 1
        fi
    }

}

__init_foundry
