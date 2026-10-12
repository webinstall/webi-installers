#!/bin/sh
set -e
set -u

__init_bat() {

    ###############
    # Install bat #
    ###############

    WEBI_SINGLE=true

    pkg_get_current_version() {
        # 'bat --version' has output in this format:
        #       bat 0.15.4
        # This trims it down to just the version number:
        #       0.15.4
        bat --version 2> /dev/null | head -n 1 | cut -d' ' -f 2
    }

    pkg_install() {
        # ~/.local/bin
        mkdir -p "$pkg_src_bin"

        # mv ./bat-*/bat ~/.local/opt/bat-v0.15.4/bin/bat
        mv ./bat-*/bat "$pkg_src_cmd"

        # chmod a+x ~/.local/opt/bat-v0.15.4/bin/bat
        chmod a+x "$pkg_src_cmd"

        # install completions if present (autocomplete/)
        if test -d ./bat-*/autocomplete; then
            mkdir -p "$pkg_src_dir/share/bash-completion/completions"
            mkdir -p "$pkg_src_dir/share/fish/vendor_completions.d"
            mkdir -p "$pkg_src_dir/share/zsh/site-functions"
            mv ./bat-*/autocomplete/bat.bash "$pkg_src_dir/share/bash-completion/completions/bat" 2>/dev/null || true
            mv ./bat-*/autocomplete/bat.fish "$pkg_src_dir/share/fish/vendor_completions.d/bat.fish" 2>/dev/null || true
            mv ./bat-*/autocomplete/bat.zsh "$pkg_src_dir/share/zsh/site-functions/_bat" 2>/dev/null || true
        fi

        # install man page if present
        if test -f ./bat-*/bat.1; then
            mkdir -p "$pkg_src_dir/share/man/man1"
            mv ./bat-*/bat.1 "$pkg_src_dir/share/man/man1/bat.1"
        fi

        if ! [ -e ~/.config/bat/config ]; then
            mkdir -p ~/.config/bat/
            touch ~/.config/bat/config
        fi
    }
}

__init_bat
