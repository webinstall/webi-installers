#!/bin/sh

# shellcheck disable=SC2034
# "'pkg_cmd_name' appears unused. Verify it or export it."

__init_cmake() {
    set -e
    set -u

    ##################
    # Install cmake #
    ##################

    # Every package should define these 6 variables
    pkg_cmd_name="cmake"

    pkg_dst_cmd="$HOME/.local/bin/cmake"
    pkg_dst="$pkg_dst_cmd"

    pkg_src_cmd="$HOME/.local/opt/cmake-v$WEBI_VERSION/bin/cmake"
    pkg_share_cmd="$HOME/.local/opt/cmake-v$WEBI_VERSION/share"
    pkg_src_dir="$HOME/.local/opt/cmake-v$WEBI_VERSION"
    pkg_src="$pkg_src_cmd"

    # pkg_install must be defined by every package
    pkg_install() {
        # ~/.local/opt/cmake-v0.99.9/bin
        mkdir -p "$(dirname "${pkg_src_cmd}")"

        # mv ./cmake-*/cmake ~/.local/opt/cmake-v0.99.9/bin/cmake
        mv ./cmake-*/bin/cmake "${pkg_src_cmd}"
        mv ./cmake-*/share "${pkg_share_cmd}"
    }

    # pkg_get_current_version is recommended, but not required
    pkg_get_current_version() {
        # 'cmake --version' has output in this format:
        #       cmake 0.99.9 (rev abcdef0123)
        # This trims it down to just the version number:
        #       0.99.9
        cmake --version 2> /dev/null |
            head -n 1 |
            cut -d ' ' -f 2
    }

}

__init_cmake
