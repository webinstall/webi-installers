#!/bin/sh
set -e
set -u

__init_duckdns_sh() {

    ######################
    # Install duckdns.sh #
    ######################

    # Every package should define these 6 variables
    pkg_cmd_name="duckdns.sh"

    pkg_dst_cmd="$HOME/.local/bin/duckdns.sh"
    pkg_dst="$pkg_dst_cmd"

    pkg_src_cmd="$HOME/.local/opt/duckdns.sh-v$WEBI_VERSION/bin/duckdns.sh"
    pkg_src_dir="$HOME/.local/opt/duckdns.sh-v$WEBI_VERSION"
    pkg_src="$pkg_src_cmd"

    # pkg_install must be defined by every package
    pkg_install() {
        # ~/.local/opt/duckdns.sh-v1.0.3/bin
        mkdir -p "$(dirname "$pkg_src_cmd")"

        # mv ./*DuckDNS.sh*/duckdns.sh ~/.local/opt/duckdns.sh-v1.0.3/bin/duckdns.sh
        mv ./*DuckDNS.sh*/duckdns.sh "$pkg_src_cmd"
    }

    # pkg_get_current_version is recommended, but (soon) not required
    pkg_get_current_version() {
        # 'duckdns.sh version' has output in this format:
        #       DuckDNS.sh v1.0.3 (2023-01-15 00:49:52 +0000)
        #       Copyright 2023 AJ ONeal
        # This trims it down to just the version number:
        #       1.0.3
        duckdns.sh version | head -n 1 | cut -d ' ' -f 2 | sed 's:^v::'
    }
}

__init_duckdns_sh
