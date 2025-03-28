#!/bin/sh
# shellcheck disable=SC2034

__init_telegram_owl() {
    set -e
    set -u

    ####################
    # Install telegram-owl #
    ####################

    # Every package should define these 6 variables
    pkg_cmd_name="telegram-owl"

    pkg_dst_cmd="${HOME}/.local/bin/telegram-owl"
    pkg_dst="${pkg_dst_cmd}"

    pkg_src_cmd="${HOME}/.local/opt/telegram-owl-v${WEBI_VERSION}/bin/telegram-owl"
    pkg_src_dir="${HOME}/.local/opt/telegram-owl-v${WEBI_VERSION}"
    pkg_src="${pkg_src_cmd}"

    pkg_install() {
        # $HOME/.local/opt/telegram-owl-v1.0.0/bin
        mkdir -p "$(dirname "${pkg_src_cmd}")"

        # mv ./telegram-owl* "$HOME/.local/opt/telegram-owl-v1.0.0/bin/telegram-owl"
        mv ./"${pkg_cmd_name}"* "${pkg_src_cmd}"

        # chmod a+x "$HOME/.local/opt/telegram-owl-v1.0.0/bin/telegram-owl"
        chmod a+x "${pkg_src_cmd}"
    }

    pkg_get_current_version() {
        # 'telegram-owl version' has output in this format:
        #       telegram-owl v1.0.0
        # This trims it down to just the version number:
        #       1.0.0
        telegram-owl --version 2> /dev/null |
            head -n 1 |
            cut -d' ' -f2 |
            sed 's:^v::'
    }

}

__init_telegram_owl
