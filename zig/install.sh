#!/bin/sh

# shellcheck disable=SC2034
# "'pkg_cmd_name' appears unused. Verify it or export it."

__init_ziglang() {
    set -e
    set -u

    ###################
    # Install ziglang #
    ###################

    # Every package should define these 6 variables
    pkg_cmd_name="zig"

    pkg_dst_cmd="$HOME/.local/opt/zig/zig"
    pkg_dst_dir="$HOME/.local/opt/zig"
    pkg_dst="$pkg_dst_dir"

    pkg_src_cmd="$HOME/.local/opt/zig-v$WEBI_VERSION/zig"
    pkg_src_dir="$HOME/.local/opt/zig-v$WEBI_VERSION"
    pkg_src="$pkg_src_dir"

    # pkg_install must be defined by every package
    pkg_install() {
        # mv ./zig-* ~/.local/opt/zig-v0.9.1
        mv ./zig-* "${pkg_src}"
    }

    # pkg_get_current_version is recommended, but not required
    pkg_get_current_version() {
        # 'zig version' has output in this format:
        #       0.9.1
        # We're just doing a little future-proofing to keep it that way
        zig version 2> /dev/null |
            head -n 1 |
            cut -d ' ' -f 1
    }

}

__init_ziglang
