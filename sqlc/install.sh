#!/bin/sh
# shellcheck disable=SC2034

__init_sqlc() {
    set -e
    set -u

    ################
    # Install sqlc #
    ################

    # Every package should define these 6 variables
    pkg_cmd_name="sqlc"

    pkg_dst_cmd="$HOME/.local/bin/sqlc"
    pkg_dst="$pkg_dst_cmd"

    pkg_src_cmd="$HOME/.local/opt/sqlc-v$WEBI_VERSION/bin/sqlc"
    pkg_src_dir="$HOME/.local/opt/sqlc-v$WEBI_VERSION"
    pkg_src="$pkg_src_cmd"

    pkg_install() {
        # mkdir -p "$HOME/.local/opt/sqlc-v1.27.0/bin"
        mkdir -p "$(dirname "$pkg_src_cmd")"

        # mv ./sqlc* "$HOME/.local/opt/sqlc-v1.27.0/bin/sqlc"
        mv ./"$pkg_cmd_name"* "$pkg_src_cmd"

        # chmod a+x "$HOME/.local/opt/sqlc-v1.27.0/bin/sqlc"
        chmod a+x "$pkg_src_cmd"
    }

    pkg_get_current_version() {
        # 'sqlc version' has output in this format:
        #       v1.27.0
        # This trims it down to just the version number:
        #       1.27.0
        sqlc version 2> /dev/null |
            head -n 1 |
            sed 's:^v::'
    }
}
__init_sqlc
