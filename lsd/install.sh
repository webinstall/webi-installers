#!/bin/sh
set -e
set -u

__init_lsd() {

    ###############
    # Install lsd #
    ###############

    # Every package should define these 6 variables
    pkg_cmd_name="lsd"

    pkg_dst_cmd="$HOME/.local/bin/lsd"
    pkg_dst="$pkg_dst_cmd"

    pkg_src_cmd="$HOME/.local/opt/lsd-v$WEBI_VERSION/bin/lsd"
    pkg_src_dir="$HOME/.local/opt/lsd-v$WEBI_VERSION"
    pkg_src="$pkg_src_cmd"

    # pkg_install must be defined by every package
    pkg_install() {
        # ~/.local/opt/lsd-v0.17.0/bin
        mkdir -p "$(dirname "$pkg_src_cmd")"

        # mv ./lsd-*/lsd ~/.local/opt/lsd-v0.17.0/bin/lsd
        mv ./lsd-*/lsd "$pkg_src_cmd"

        # install completions if present (autocomplete/{_lsd,lsd.fish,lsd.bash-completion})
        if test -d ./lsd-*/autocomplete; then
            mkdir -p "$pkg_src_dir/share/bash-completion/completions"
            mkdir -p "$pkg_src_dir/share/fish/vendor_completions.d"
            mkdir -p "$pkg_src_dir/share/zsh/site-functions"
            mv ./lsd-*/autocomplete/lsd.bash-completion "$pkg_src_dir/share/bash-completion/completions/lsd" 2>/dev/null || true
            mv ./lsd-*/autocomplete/lsd.fish "$pkg_src_dir/share/fish/vendor_completions.d/lsd.fish" 2>/dev/null || true
            mv ./lsd-*/autocomplete/_lsd "$pkg_src_dir/share/zsh/site-functions/_lsd" 2>/dev/null || true
        fi

        # install man page if present
        if test -f ./lsd-*/lsd.1; then
            mkdir -p "$pkg_src_dir/share/man/man1"
            mv ./lsd-*/lsd.1 "$pkg_src_dir/share/man/man1/lsd.1"
        fi
    }

    # pkg_get_current_version is recommended, but (soon) not required
    pkg_get_current_version() {
        # 'lsd --version' has output in this format:
        #       lsd 0.17.0
        # This trims it down to just the version number:
        #       0.17.0
        lsd --version 2> /dev/null | head -n 1 | cut -d ' ' -f 2
    }

}

__init_lsd
