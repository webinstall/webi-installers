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

    pkg_dst_cmd="$HOME/.local/opt/cmake/bin/cmake"
    pkg_dst_dir="$HOME/.local/opt/cmake"
    pkg_dst="$pkg_dst_dir"

    pkg_src_cmd="$HOME/.local/opt/cmake-v$WEBI_VERSION/bin/cmake"
    pkg_src_dir="$HOME/.local/opt/cmake-v$WEBI_VERSION"
    pkg_src="$pkg_src_dir"

    # pkg_install must be defined by every package
    pkg_install() {
        # ~/.local/opt/cmake-v3.27.0/
        mkdir -p "$(dirname "${pkg_src_dir}")"

        # mv ./cmake-*/ ~/.local/opt/cmake-v3.27.0/
        mv ./cmake-*/ "${pkg_src_dir}"
    }

    # pkg_get_current_version is recommended, but not required
    pkg_get_current_version() {
        # 'cmake --version' has output in this format:
        #       cmake 3.27.0 (rev abcdef0123)
        # This trims it down to just the version number:
        #       3.27.0
        cmake --version 2> /dev/null |
            head -n 1 |
            cut -d ' ' -f 3
    }

}

__init_cmake
