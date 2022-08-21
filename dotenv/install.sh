#!/bin/sh

__init_dotenv() {
    set -e
    set -u

    ##################
    # Install dotenv #
    ##################

    # Every package should define these 6 variables
    pkg_cmd_name="dotenv"

    pkg_dst_cmd="$HOME/.local/bin/dotenv"
    pkg_dst="$pkg_dst_cmd"

    pkg_src_cmd="$HOME/.local/opt/dotenv-v$WEBI_VERSION/bin/dotenv"
    pkg_src_dir="$HOME/.local/opt/dotenv-v$WEBI_VERSION"
    pkg_src="$pkg_src_cmd"

    pkg_install() {
        # $HOME/.local/opt/dotenv-v1.0.0/bin
        mkdir -p "$pkg_src_bin"

        # mv ./dotenv* "$HOME/.local/opt/dotenv-v1.0.0/bin/dotenv"
        mv ./"$pkg_cmd_name"* "$pkg_src_cmd"

        # chmod a+x "$HOME/.local/opt/dotenv-v1.0.0/bin/dotenv"
        chmod a+x "$pkg_src_cmd"
    }

    pkg_get_current_version() {
        # 'dotenv version' has output in this format:
        #       dotenv v1.0.0 (17c7677) 2020-10-19T23:43:57Z
        # This trims it down to just the version number:
        #       1.0.0
        dotenv --version 2> /dev/null | head -n 1 | cut -d' ' -f2 | sed 's:^v::'
    }

}

__init_dotenv
