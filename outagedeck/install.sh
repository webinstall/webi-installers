#!/bin/sh
# shellcheck disable=SC2034

set -e
set -u

__init_outagedeck() {
    pkg_cmd_name="outagedeck"

    pkg_dst_cmd="${HOME}/.local/bin/outagedeck"
    pkg_dst="${pkg_dst_cmd}"

    pkg_src_cmd="${HOME}/.local/opt/outagedeck-v${WEBI_VERSION}/bin/outagedeck"
    pkg_src_dir="${HOME}/.local/opt/outagedeck-v${WEBI_VERSION}"
    pkg_src="${pkg_src_cmd}"

    pkg_install() {
        mkdir -p "$(dirname "${pkg_src_cmd}")"
        mv ./outagedeck "${pkg_src_cmd}"
    }

    pkg_get_current_version() {
        outagedeck --version 2> /dev/null | head -n 1
    }
}

__init_outagedeck
