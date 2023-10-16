#!/bin/sh

__init_sqlpkg() {
    set -e
    set -u

    ####################
    # Install sqlpkg #
    ####################

    # Every package should define these 6 variables
    pkg_cmd_name="sqlpkg"

    pkg_dst_cmd="$HOME/.local/bin/sqlpkg"
    pkg_dst="$pkg_dst_cmd"

    pkg_src_cmd="$HOME/.local/opt/sqlpkg-v$WEBI_VERSION/bin/sqlpkg"
    pkg_src_dir="$HOME/.local/opt/sqlpkg-v$WEBI_VERSION"
    pkg_src="$pkg_src_cmd"

    pkg_install() {
        # $HOME/.local/opt/sqlpkg-v0.2.2/bin
        mkdir -p "$(dirname "$pkg_src_cmd")"

        # mv ./sqlpkg* "$HOME/.local/opt/sqlpkg-v0.2.2/bin/sqlpkg"
        mv ./"$pkg_cmd_name"* "$pkg_src_cmd"

        # chmod a+x "$HOME/.local/opt/sqlpkg-v0.2.2/bin/sqlpkg"
        chmod a+x "$pkg_src_cmd"
    }

    pkg_get_current_version() {
        # 'sqlpkg version' has output in this format:
        #       0.2.2
        # This makes it resistant to future added lines or columns
        sqlpkg version 2> /dev/null | head -n 1 | cut -f 1
    }

}

__init_sqlpkg
