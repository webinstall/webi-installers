#!/bin/sh

# shellcheck disable=SC2034
# "'pkg_cmd_name' appears unused. Verify it or export it."

__init_tinygo() {
    set -e
    set -u

    ##################
    # Install tinygo #
    ##################

    # Every package should define these 6 variables
    pkg_cmd_name="tinygo"

    pkg_dst_cmd="$HOME/.local/opt/tinygo/bin/tinygo"
    pkg_dst_dir="$HOME/.local/opt/tinygo"
    pkg_dst="$pkg_dst_dir"

    pkg_src_cmd="$HOME/.local/opt/tinygo-v$WEBI_VERSION/bin/tinygo"
    pkg_src_dir="$HOME/.local/opt/tinygo-v$WEBI_VERSION"
    pkg_src="$pkg_src_dir"

    # pkg_install must be defined by every package
    pkg_install() {
        echo "Checking for Go compiler..."
        if ! command -v go 2> /dev/null; then
            "$HOME/.local/bin/webi" go
            export PATH="$HOME/.local/opt/go/bin:$PATH"
        fi

        # ~/.local/opt/tinygo-v0.30.0/
        mkdir -p "$(dirname "${pkg_src_dir}")"

        # mv ./tinygo*/ ~/.local/opt/tinygo-v0.30.0/
        mv ./tinygo*/ "${pkg_src_dir}"
    }

    # pkg_get_current_version is recommended, but not required
    pkg_get_current_version() {
        # 'tinygo --version' has output in this format:
        #       tinygo version 0.30.0 darwin/amd64 (using go version go1.21.1 and LLVM version 16.0.1)
        # This trims it down to just the version number:
        #       0.30.0
        tinygo version 2> /dev/null |
            head -n 1 |
            cut -d' ' -f3
    }

}

__init_tinygo
