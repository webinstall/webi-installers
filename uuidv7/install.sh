#!/bin/sh
# shellcheck disable=SC2034

__init_uuidv7() {
    set -e
    set -u

    ##################
    # Install uuidv7 #
    ##################

    # Every package should define these 6 variables
    pkg_cmd_name="uuidv7"

    pkg_dst_cmd="${HOME}/.local/bin/uuidv7"
    pkg_dst="${pkg_dst_cmd}"

    pkg_src_cmd="${HOME}/.local/opt/uuidv7-v${WEBI_VERSION}/bin/uuidv7"
    pkg_src_dir="${HOME}/.local/opt/uuidv7-v${WEBI_VERSION}"
    pkg_src="${pkg_src_cmd}"

    pkg_install() {
        # $HOME/.local/opt/uuidv7-v1.0.1/bin
        mkdir -p "$(dirname "${pkg_src_cmd}")"

        # mv ./uuidv7* "$HOME/.local/opt/uuidv7-v1.0.1/bin/uuidv7"
        mv ./"${pkg_cmd_name}"* "${pkg_src_cmd}"

        # chmod a+x "$HOME/.local/opt/uuidv7-v1.0.1/bin/uuidv7"
        chmod a+x "${pkg_src_cmd}"
    }

    pkg_get_current_version() {
        # TODO https://github.com/coolaj86/uuidv7/issues/10
        echo '1.0.1'
    }

}

__init_uuidv7
