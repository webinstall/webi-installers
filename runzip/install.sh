#!/bin/sh
# shellcheck disable=SC2034

__init_runzip() {
    set -e
    set -u

    ####################
    # Install runzip #
    ####################

    # Every package should define these 6 variables
    pkg_cmd_name="runzip"

    pkg_dst_cmd="${HOME}/.local/bin/runzip"
    pkg_dst="${pkg_dst_cmd}"

    pkg_src_cmd="${HOME}/.local/opt/runzip-v${WEBI_VERSION}/bin/runzip"
    pkg_src_dir="${HOME}/.local/opt/runzip-v${WEBI_VERSION}"
    pkg_src="${pkg_src_cmd}"

    pkg_install() {
        # $HOME/.local/opt/runzip-v1.0.0/bin
        mkdir -p "$(dirname "${pkg_src_cmd}")"

        # mv ./runzip* "$HOME/.local/opt/runzip-v1.0.0/bin/runzip"
        mv ./"${pkg_cmd_name}"* "${pkg_src_cmd}"

        # chmod a+x "$HOME/.local/opt/runzip-v1.0.0/bin/runzip"
        chmod a+x "${pkg_src_cmd}"
    }

    pkg_get_current_version() {
        # 'runzip version' has output in this format:
        #       runzip v1.0.0 (1234567) 2024-09-13T12:25:00Z
        # This trims it down to just the version number:
        #       1.0.0
        runzip --version 2> /dev/null |
            head -n 1 |
            cut -d' ' -f2 |
            sed 's:^v::'
    }

}

__init_runzip
