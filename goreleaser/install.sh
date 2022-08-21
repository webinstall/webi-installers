#!/bin/sh
set -e
set -u

__init_goreleaser() {

    ######################
    # Install goreleaser #
    ######################

    # Every package should define these 6 variables
    pkg_cmd_name="goreleaser"

    pkg_dst_cmd="$HOME/.local/bin/goreleaser"
    pkg_dst="$pkg_dst_cmd"

    pkg_src_cmd="$HOME/.local/opt/goreleaser-v$WEBI_VERSION/bin/goreleaser"
    pkg_src_dir="$HOME/.local/opt/goreleaser-v$WEBI_VERSION"
    pkg_src="$pkg_src_cmd"

    # pkg_install must be defined by every package
    pkg_install() {
        # ~/.local/opt/goreleaser-v0.99.9/bin
        mkdir -p "$(dirname "$pkg_src_cmd")"

        # mv ./goreleaser-*/goreleaser ~/.local/opt/goreleaser-v0.99.9/bin/goreleaser
        mv ./goreleaser "$pkg_src_cmd"
    }

    # pkg_get_current_version is recommended, but (soon) not required
    pkg_get_current_version() {
        # 'goreleaser --version' has output in this format:
        #       goreleaser 0.99.9 (rev abcdef0123)
        # This trims it down to just the version number:
        #       0.99.9
        goreleaser --version 2> /dev/null | head -n 1 | cut -d ' ' -f 2
    }

}

__init_goreleaser
