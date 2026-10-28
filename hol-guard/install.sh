#!/bin/sh
set -e
set -u

__init_hol_guard() {
    pkg_cmd_name="hol-guard"

    # Release assets are standalone executables, not archives.
    WEBI_SINGLE=true
    pkg_dst_cmd="$HOME/.local/bin/hol-guard"
    pkg_dst="$pkg_dst_cmd"
    pkg_src_cmd="$HOME/.local/opt/hol-guard-v$WEBI_VERSION/bin/hol-guard"
    pkg_src_dir="$HOME/.local/opt/hol-guard-v$WEBI_VERSION"
    pkg_src="$pkg_src_cmd"

    pkg_install() {
        mkdir -p "$(dirname "$pkg_src_cmd")"
        mv ./hol-guard-core-* "$pkg_src_cmd"
        chmod a+x "$pkg_src_cmd"
    }

    pkg_get_current_version() {
        hol-guard --version 2> /dev/null | head -n 1 | cut -d ' ' -f 2
    }
}

__init_hol_guard
