#!/bin/sh
set -e
set -u

__init_dotenv_linter() {

    #########################
    # Install dotenv-linter #
    #########################

    # Every package should define these 6 variables
    pkg_cmd_name="dotenv-linter"

    pkg_dst_cmd="$HOME/.local/bin/dotenv-linter"
    pkg_dst="$pkg_dst_cmd"

    pkg_src_cmd="$HOME/.local/opt/dotenv-linter-v$WEBI_VERSION/bin/dotenv-linter"
    pkg_src_dir="$HOME/.local/opt/dotenv-linter-v$WEBI_VERSION"
    pkg_src="$pkg_src_cmd"

    # pkg_install must be defined by every package
    pkg_install() {
        # ~/.local/opt/dotenv-linter-v0.99.9/bin
        mkdir -p "$(dirname "$pkg_src_cmd")"

        # mv ./dotenv-linter-*/dotenv-linter ~/.local/opt/dotenv-linter-v0.99.9/bin/dotenv-linter
        mv ./dotenv-linter "$pkg_src_cmd"
    }

    # pkg_get_current_version is recommended, but (soon) not required
    pkg_get_current_version() {
        # 'dotenv-linter --version' has output in this format:
        #       dotenv-linter 0.99.9 (rev abcdef0123)
        # This trims it down to just the version number:
        #       0.99.9
        dotenv-linter --version 2> /dev/null | head -n 1 | cut -d ' ' -f 2
    }

}

__init_dotenv_linter
