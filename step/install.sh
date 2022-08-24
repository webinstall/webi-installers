#!/bin/sh

# shellcheck disable=SC2034
# "'pkg_cmd_name' appears unused. Verify it or export it."

__init_step() {
    set -e
    set -u

    ##################
    # Install step #
    ##################

    # Every package should define these 6 variables
    pkg_cmd_name="step"

    pkg_dst_cmd="$HOME/.local/bin/step"
    pkg_dst="$pkg_dst_cmd"

    pkg_src_cmd="$HOME/.local/opt/step-v$WEBI_VERSION/bin/step"
    pkg_src_dir="$HOME/.local/opt/step-v$WEBI_VERSION"
    pkg_src="$pkg_src_cmd"

    # pkg_install must be defined by every package
    pkg_install() {
        # ~/.local/opt/step-v0.99.9/bin
        mkdir -p "$(dirname "${pkg_src_cmd}")"

        # mv ./step-*/step ~/.local/opt/step-v0.99.9/bin/step
        mv ./step-$WEBI_VERSION/$WEBI_VERSION "${pkg_src_cmd}"
    }

    # pkg_get_current_version is recommended, but not required
    pkg_get_current_version() {
        # 'step --version' has output in this format:
        #       step 0.99.9 (rev abcdef0123)
        # This trims it down to just the version number:
        #       0.99.9
        step --version 2> /dev/null |
            head -n 1 |
            cut -d ' ' -f 2
    }

}

__init_step
