#!/bin/sh

__init_serviceman() {
    set -e
    set -u

    ######################
    # Install serviceman #
    ######################

    # Every package should define these 6 variables
    pkg_cmd_name="serviceman"

    pkg_dst_cmd="$HOME/.local/bin/serviceman"
    pkg_dst="$pkg_dst_cmd"

    pkg_src_cmd="$HOME/.local/opt/serviceman-v$WEBI_VERSION/bin/serviceman"
    pkg_src_dir="$HOME/.local/opt/serviceman-v$WEBI_VERSION"
    pkg_src="$pkg_src_cmd"

    pkg_install() {
        # $HOME/.local/opt/serviceman-v0.8.0/bin
        mkdir -p "$pkg_src_bin"

        # mv ./serviceman* "$HOME/.local/opt/serviceman-v0.8.0/bin/serviceman"
        mv ./"$pkg_cmd_name"* "$pkg_src_cmd"

        # chmod a+x "$HOME/.local/opt/serviceman-v0.8.0/bin/serviceman"
        chmod a+x "$pkg_src_cmd"
    }

    pkg_get_current_version() {
        # 'serviceman version' has output in this format:
        #       serviceman v0.8.0 (f3ab547) 2020-12-02T16:19:10-07:00
        # This trims it down to just the version number:
        #       0.8.0
        serviceman --version 2> /dev/null | head -n 1 | cut -d' ' -f2 | sed 's:^v::'
    }

}

__init_serviceman
