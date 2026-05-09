#!/bin/sh
# shellcheck disable=SC2034

set -e
set -u

__init_basecamp() {
    pkg_cmd_name="basecamp"

    pkg_src_dir="$HOME/.local/opt/basecamp-cli-v$WEBI_VERSION"
    pkg_src_cmd="$pkg_src_dir/bin/basecamp"
    pkg_src="$pkg_src_cmd"

    pkg_dst_cmd="$HOME/.local/bin/basecamp"
    pkg_dst="$pkg_dst_cmd"

    pkg_install() {
        mkdir -p "$(dirname "$pkg_src_cmd")"
        mkdir -p "$pkg_src_dir/completions"

        if test -f ./basecamp; then
            mv ./basecamp "$pkg_src_cmd"
        elif test -e ./basecamp-*/basecamp; then
            mv ./basecamp-*/basecamp "$pkg_src_cmd"
        elif test -e ./basecamp-*; then
            mv ./basecamp-* "$pkg_src_cmd"
        else
            echo >&2 "failed to find 'basecamp' executable"
            return 1
        fi

        if test -d ./completions; then
            cp -a ./completions/. "$pkg_src_dir/completions/"
        fi
    }

    pkg_get_current_version() {
        basecamp --version 2> /dev/null |
            head -n 1 |
            cut -d' ' -f3
    }
}

__init_basecamp
