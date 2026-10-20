#!/bin/sh
# shellcheck disable=SC2034

set -e
set -u

__init_gha_doctor() {
    ######################
    # Install gha-doctor #
    ######################

    pkg_cmd_name="gha-doctor"

    pkg_dst_cmd="${HOME}/.local/bin/gha-doctor"
    pkg_dst="${pkg_dst_cmd}"

    pkg_src_cmd="${HOME}/.local/opt/gha-doctor-v${WEBI_VERSION}/bin/gha-doctor"
    pkg_src_dir="${HOME}/.local/opt/gha-doctor-v${WEBI_VERSION}"
    pkg_src="${pkg_src_cmd}"

    pkg_install() {
        # $HOME/.local/opt/gha-doctor-v0.66.0/bin
        mkdir -p "$(dirname "${pkg_src_cmd}")"

        # goreleaser-style archive: bare binary at the archive root
        mv ./gha-doctor "${pkg_src_cmd}"

        chmod a+x "${pkg_src_cmd}"
    }

    pkg_get_current_version() {
        # 'gha-doctor --version' has output in this format:
        #       gha-doctor 0.66.0
        # This trims it down to just the version number:
        #       0.66.0
        gha-doctor --version 2> /dev/null | head -n 1 | cut -d ' ' -f 2
    }
}

__init_gha_doctor
