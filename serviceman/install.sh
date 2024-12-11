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
    # shellcheck disable=SC2034
    pkg_dst="$pkg_dst_cmd"

    pkg_src_cmd="$HOME/.local/opt/serviceman-v$WEBI_VERSION/bin/serviceman"
    pkg_src_bin="$HOME/.local/opt/serviceman-v$WEBI_VERSION/bin"
    pkg_src_dir="$HOME/.local/opt/serviceman-v$WEBI_VERSION"
    # shellcheck disable=SC2034
    pkg_src="$pkg_src_cmd"

    pkg_install() {
        if test -e ./*"$pkg_cmd_name"*/share; then
            rm -rf "${pkg_src_dir}"
            # mv ./bnnanet-serviceman-* "$HOME/.local/opt/serviceman-v0.9.1"
            mv ./*"$pkg_cmd_name"*/ "${pkg_src_dir}"
        else
            echo "NO share"
            # $HOME/.local/opt/serviceman-v0.8.0/bin
            mkdir -p "$pkg_src_bin"

            # mv ./serviceman* "$HOME/.local/opt/serviceman-v0.8.0/bin/serviceman"
            mv ./"$pkg_cmd_name"* "$pkg_src_cmd"

            # chmod a+x "$HOME/.local/opt/serviceman-v0.8.0/bin/serviceman"
            chmod a+x "$pkg_src_cmd"
        fi
    }

    pkg_link() {
        (
            cd ~/.local/opt/ || return 1
            rm -rf ./serviceman
            ln -s "serviceman-v$WEBI_VERSION" 'serviceman'
        )

        (
            mkdir -p ~/.local/share/
            cd ~/.local/share/ || return 1
            rm -rf ./serviceman
            ln -s "../opt/serviceman-v$WEBI_VERSION/share/serviceman" 'serviceman'
        )

        (
            mkdir -p ~/.local/bin/
            cd ~/.local/bin/ || return 1
            rm -rf ./serviceman
            ln -s "../opt/serviceman-v$WEBI_VERSION/bin/serviceman" 'serviceman'
        )
    }

    pkg_get_current_version() {
        # 'serviceman version' has output in this format:
        #       serviceman v0.9.1 (2024-12-11 14:29 -0500)
        #       Copyright 2024 AJ ONeal
        #       Licensed under the MPL-2.0
        # This trims it down to just the version number:
        #       0.9.1
        serviceman --version 2> /dev/null | head -n 1 | cut -d' ' -f2 | sed 's:^v::'
    }

}

__init_serviceman
