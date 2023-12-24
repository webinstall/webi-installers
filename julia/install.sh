#!/bin/sh

# shellcheck disable=SC2034
# "'pkg_cmd_name' appears unused. Verify it or export it."

__init_julia() {
    set -e
    set -u

    ##################
    # Install julia #
    ##################

    # Every package should define these 6 variables
    pkg_cmd_name="julia"

    pkg_dst_cmd="$HOME/.local/opt/julia/bin/julia"
    pkg_dst_dir="$HOME/.local/opt/julia"
    pkg_dst="$pkg_dst_dir"

    pkg_src_cmd="$HOME/.local/opt/julia-v$WEBI_VERSION/bin/julia"
    pkg_src_dir="$HOME/.local/opt/julia-v$WEBI_VERSION"
    pkg_src="$pkg_src_dir"

    # pkg_install must be defined by every package
    pkg_install() {
        # ~/.local/opt/julia-v3.27.0/
        mkdir -p "$(dirname "${pkg_src_dir}")"

        # mv ./julia-*/ ~/.local/opt/julia-v3.27.0/
        mv ./julia-*/ "${pkg_src_dir}"
    }

    # pkg_get_current_version is recommended, but not required
    pkg_get_current_version() {
        # 'julia --version' has output in this format:
        #       julia version 1.10.0-rc1
        # This trims it down to just the version number:
        #       1.10.0-rc1
        julia --version 2> /dev/null |
            head -n 1 |
            cut -d ' ' -f 3
    }

}

__init_julia
