#!/bin/sh
set -e
set -u

# shellcheck disable=SC2034
# "'pkg_cmd_name' appears unused. Verify it or export it."

__init_delta() {

    #################
    # Install delta #
    #################

    # Every package should define these 6 variables
    pkg_cmd_name="delta"

    pkg_dst_cmd="$HOME/.local/bin/delta"
    pkg_dst="$pkg_dst_cmd"

    pkg_src_cmd="$HOME/.local/opt/delta-v$WEBI_VERSION/bin/delta"
    pkg_src_dir="$HOME/.local/opt/delta-v$WEBI_VERSION"
    pkg_src="$pkg_src_cmd"

    # pkg_install must be defined by every package
    pkg_install() {
        # ~/.local/opt/delta-v0.99.9/bin
        mkdir -p "$(dirname "$pkg_src_cmd")"

        # mv ./delta-*/delta ~/.local/opt/delta-v0.99.9/bin/delta
        mv ./delta-*/delta "$pkg_src_cmd"

        git config --global page.diff delta
        git config --global page.show delta
        git config --global page.log delta
        git config --global page.blame delta
        git config --global page.reflog delta

        git config --global interactive.diffFilter 'delta --color-only'
    }

    # pkg_get_current_version is recommended, but not required
    pkg_get_current_version() {
        # 'delta --version' has output in this format:
        #       delta 0.9.2
        # This trims it down to just the version number:
        #       0.9.2
        delta --version 2> /dev/null |
            head -n 1 |
            cut -d ' ' -f 2
    }

}

__init_delta
