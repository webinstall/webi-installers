#!/bin/sh

# shellcheck disable=SC2034
# "'pkg_cmd_name' appears unused. Verify it or export it."

__init_neovim() {
    set -e
    set -u

    ##################
    # Install neovim #
    ##################

    # Every package should define these 6 variables
    pkg_cmd_name="nvim"

    pkg_dst_cmd="$HOME/.local/opt/neovim/bin/nvim"
    pkg_dst_dir="$HOME/.local/opt/neovim"
    pkg_dst="$pkg_dst_dir"

    pkg_src_cmd="$HOME/.local/opt/neovim-v$WEBI_VERSION/bin/nvim"
    pkg_src_dir="$HOME/.local/opt/neovim-v$WEBI_VERSION"
    pkg_src="$pkg_src_dir"

    # pkg_install must be defined by every package
    pkg_install() {
        # mv ./nvim-* ~/.local/opt/neovim-macos
        mv ./nvim-* "${pkg_src}"
    }

    # pkg_get_current_version is recommended, but not required
    pkg_get_current_version() {
        # 'nvim --version' has output in this format:
        # NVIM v0.7.2
        # Build type: Release
        # LuaJIT 2.1.0-beta3
        # Compiled by runner@Mac-1656256708179.local
        #
        # Features: +acl +iconv +tui
        # See ":help feature-compile"
        #
        #    system vimrc file: "$VIM/sysinit.vim"
        #   fall-back for $VIM: "/share/nvim"
        #
        # Run :checkhealth for more info

        # This trims it down to just the version number:
        #       0.7.2
        nvim --version 2> /dev/null |
            head -n 1 |
            cut -d ' ' -f 2 |
            sed 's/v//'
    }

}

__init_neovim
