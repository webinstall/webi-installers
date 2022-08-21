#!/bin/sh

__init_rclone() {
    set -e
    set -u

    ##################
    # Install rclone #
    ##################

    # Every package should define these 6 variables
    pkg_cmd_name="rclone"

    pkg_dst_cmd="$HOME/.local/bin/rclone"
    pkg_dst="$pkg_dst_cmd"

    pkg_src_cmd="$HOME/.local/opt/rclone-v$WEBI_VERSION/bin/rclone"
    pkg_src_dir="$HOME/.local/opt/rclone-v$WEBI_VERSION"
    pkg_src="$pkg_src_cmd"

    pkg_install() {
        # $HOME/.local/opt/rclone-v0.6.5/bin
        mkdir -p "$(dirname "$pkg_src_cmd")"

        # mv ./rclone* "$HOME/.local/opt/rclone-v0.6.5/bin/rclone"
        mv ./rclone*/rclone "$pkg_src_cmd"

        # chmod a+x "$HOME/.local/opt/rclone-v0.6.5/bin/rclone"
        chmod a+x "$pkg_src_cmd"
    }

    pkg_get_current_version() {
        # 'rclone version' has output in this format:
        #       rclone v1.54.0
        #       - os/arch: darwin/amd64
        #       - go version: go1.15.7
        # This trims it down to just the version number:
        #       1.54.0
        rclone --version 2> /dev/null | head -n 1 | cut -d' ' -f2 | sed 's:^v::'
    }

}

__init_rclone
