#!/bin/sh
# shellcheck disable=SC2034

__init_hanko() {
    set -e
    set -u

    ##################
    # Install hanko  #
    ##################

    # Every package should define these 6 variables
    pkg_cmd_name="hanko"

    pkg_dst_cmd="${HOME}/.local/bin/hanko"
    pkg_dst="${pkg_dst_cmd}"

    pkg_src_cmd="${HOME}/.local/opt/hanko-v${WEBI_VERSION}/bin/hanko"
    pkg_src_dir="${HOME}/.local/opt/hanko-v${WEBI_VERSION}"
    pkg_src="${pkg_src_cmd}"

    pkg_install() {
        # $HOME/.local/opt/hanko-v1.0.1/bin
        mkdir -p "$(dirname "${pkg_src_cmd}")"

        # mv ./hanko* "$HOME/.local/opt/hanko-v1.0.1/bin/hanko"
        mv ./"${pkg_cmd_name}"* "${pkg_src_cmd}"

        # chmod a+x "$HOME/.local/opt/hanko-v1.0.1/bin/hanko"
        chmod a+x "${pkg_src_cmd}"
    }

    pkg_get_current_version() {
        # 'hanko --version' has output in this format:
        #       hanko 0.5.1
        # This trims it down to just the version number:
        #       0.5.1
        hanko --version 2> /dev/null | head -n 1 | cut -d ' ' -f 2
    }

}

__init_hanko
