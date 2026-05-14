#!/bin/sh
set -e
set -u

__init_watchexec() {

    #####################
    # Install watchexec #
    #####################

    # Every package should define these 6 variables
    pkg_cmd_name="watchexec"

    pkg_dst_cmd="$HOME/.local/bin/watchexec"
    pkg_dst="$pkg_dst_cmd"

    pkg_src_cmd="$HOME/.local/opt/watchexec-v$WEBI_VERSION/bin/watchexec"
    pkg_src_dir="$HOME/.local/opt/watchexec-v$WEBI_VERSION"
    pkg_src="$pkg_src_cmd"

    # pkg_install must be defined by every package
    pkg_install() {
        # ~/.local/opt/watchexec-v0.99.9/bin
        mkdir -p "$(dirname "$pkg_src_cmd")"

        # mv ./watchexec-*/watchexec ~/.local/opt/watchexec-v0.99.9/bin/watchexec
        mv ./watchexec-*/watchexec "$pkg_src_cmd"

        # install completions if present (completions/{bash,fish,zsh})
        if test -d ./watchexec-*/completions; then
            mkdir -p "$pkg_src_dir/share/bash-completion/completions"
            mkdir -p "$pkg_src_dir/share/fish/vendor_completions.d"
            mkdir -p "$pkg_src_dir/share/zsh/site-functions"
            mv ./watchexec-*/completions/bash "$pkg_src_dir/share/bash-completion/completions/watchexec" 2>/dev/null || true
            mv ./watchexec-*/completions/fish "$pkg_src_dir/share/fish/vendor_completions.d/watchexec.fish" 2>/dev/null || true
            mv ./watchexec-*/completions/zsh "$pkg_src_dir/share/zsh/site-functions/_watchexec" 2>/dev/null || true
        fi

        # install man page if present
        if test -f ./watchexec-*/watchexec.1; then
            mkdir -p "$pkg_src_dir/share/man/man1"
            mv ./watchexec-*/watchexec.1 "$pkg_src_dir/share/man/man1/watchexec.1"
        fi
    }

    # pkg_get_current_version is recommended, but (soon) not required
    pkg_get_current_version() {
        # 'watchexec --version' has output in this format:
        #       watchexec 0.99.9
        # This trims it down to just the version number:
        #       0.99.9
        watchexec --version 2> /dev/null | head -n 1 | cut -d ' ' -f 2
    }

}

__init_watchexec
