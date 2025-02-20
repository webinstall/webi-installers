#!/bin/sh
# shellcheck disable=SC2034

set -e
set -u

__init_koji() {
    pkg_cmd_name="koji"

    pkg_src_dir="$HOME/.local/opt/koji-v$WEBI_VERSION"
    pkg_src_cmd="$pkg_src_dir/bin/koji"
    pkg_src="$pkg_src_cmd"

    pkg_dst_cmd="$HOME/.local/bin/koji"
    pkg_dst="$pkg_dst_cmd"

    # pkg_install must be defined by every package
    pkg_install() {
        # ~/.local/opt/koji-v1.5.0/bin
        mkdir -p "$(dirname "$pkg_src_cmd")"

        if test -f ./koji; then
            # mv koji ~/.local/opt/koji-v1.5.0/bin/koji
            mv ./koji "$pkg_src_cmd"
        elif test -e ./koji-*/koji; then
            # mv koji-1.4.0/koji ~/.local/opt/koji-v1.4.0/bin/koji
            mv ./koji-*/koji "$pkg_src_cmd"
        elif test -e ./koji-*; then
            # mv koji-linux-amd64 ~/.local/opt/koji-v1.2.0/bin/koji
            mv ./koji-* "$pkg_src_cmd"
        else
            echo >&2 "failed to find 'koji' exectutable"
            return 1
        fi
    }

    # pkg_get_current_version is recommended, but (soon) not required
    pkg_get_current_version() {
        # 'koji --version' has output in this format:
        #       koji 1.5.0
        # This trims it down to just the version number:
        #       1.5.0
        koji --version 2> /dev/null | head -n 1 | cut -d' ' -f2
    }
}

__init_koji
