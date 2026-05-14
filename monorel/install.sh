#!/bin/sh
# shellcheck disable=SC2034

set -e
set -u

__init_monorel() {
    pkg_cmd_name="monorel"

    pkg_src_dir="$HOME/.local/opt/monorel-v$WEBI_VERSION"
    pkg_src_cmd="$pkg_src_dir/bin/monorel"
    pkg_src="$pkg_src_cmd"

    pkg_dst_cmd="$HOME/.local/bin/monorel"
    pkg_dst="$pkg_dst_cmd"

    # pkg_install must be defined by every package
    pkg_install() {
        # ~/.local/opt/monorel-v0.6.5/bin
        mkdir -p "$(dirname "$pkg_src_cmd")"

        # mv monorel ~/.local/opt/monorel-v0.6.5/bin/monorel
        mv ./monorel "$pkg_src_cmd"
    }

    pkg_post_install() {
        b_old_path="${PATH}"
        export PATH="$HOME/.local/bin:${PATH}"

        if ! command -v git > /dev/null; then
            "$HOME/.local/bin/webi" git
        fi

        if ! command -v gh > /dev/null; then
            "$HOME/.local/bin/webi" gh
        fi

        if ! command -v goreleaser > /dev/null; then
            "$HOME/.local/bin/webi" goreleaser
        fi

        export PATH="${b_old_path}"
    }

    pkg_get_current_version() {
        # 'monorel --version' has output in this format:
        #       monorel v0.6.6 ba674a6 (2026-03-08T23:24:03Z)
        # This trims it down to just the version number:
        #       0.6.6
        monorel --version 2> /dev/null |
            head -n 1 |
            cut -d' ' -f2 |
            cut -c 2-
    }
}

__init_monorel
