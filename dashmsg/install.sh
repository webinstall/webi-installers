#!/bin/sh

__init_dashmsg() {
    set -e
    set -u

    ####################
    # Install dashmsg #
    ####################

    # Every package should define these 6 variables
    pkg_cmd_name="dashmsg"

    pkg_dst_cmd="$HOME/.local/bin/dashmsg"
    pkg_dst="$pkg_dst_cmd"

    pkg_src_cmd="$HOME/.local/opt/dashmsg-v$WEBI_VERSION/bin/dashmsg"
    pkg_src_dir="$HOME/.local/opt/dashmsg-v$WEBI_VERSION"
    pkg_src="$pkg_src_cmd"

    pkg_install() {
        # $HOME/.local/opt/dashmsg-v0.9.0/bin
        mkdir -p "$(dirname "$pkg_src_cmd")"

        # mv ./dashmsg* "$HOME/.local/opt/dashmsg-v0.9.0/bin/dashmsg"
        mv ./"$pkg_cmd_name"* "$pkg_src_cmd"

        # chmod a+x "$HOME/.local/opt/dashmsg-v0.9.0/bin/dashmsg"
        chmod a+x "$pkg_src_cmd"
    }

    pkg_get_current_version() {
        # 'dashmsg version' has output in this format:
        #       dashmsg v0.9.0 (6d73209) 2022-03-12T09:07:43Z
        # This trims it down to just the version number:
        #       0.9.0
        dashmsg --version 2> /dev/null | head -n 1 | cut -d' ' -f2 | sed 's:^v::'
    }

}

__init_dashmsg
