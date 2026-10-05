#!/bin/sh
set -e
set -u

__init_fd() {

    ###############
    # Install fd #
    ###############

    WEBI_SINGLE=true

    pkg_get_current_version() {
        # 'fd --version' has output in this format:
        #       fd 8.1.1
        # This trims it down to just the version number:
        #       8.1.1
        fd --version 2> /dev/null | head -n 1 | cut -d' ' -f 2
    }

    pkg_install() {
        # $HOME/.local/
        mkdir -p "$pkg_src_bin"

        # mv ./fd-*/fd "$HOME/.local/opt/fd-v8.1.1/bin/fd"
        mv ./fd-*/fd "$pkg_src_cmd"

        # chmod a+x "$HOME/.local/opt/fd-v8.1.1/bin/fd"
        chmod a+x "$pkg_src_cmd"

        # install completions if present (autocomplete/{fd.bash,fd.fish,_fd})
        if test -d ./fd-*/autocomplete; then
            mkdir -p "$pkg_src_dir/share/bash-completion/completions"
            mkdir -p "$pkg_src_dir/share/fish/vendor_completions.d"
            mkdir -p "$pkg_src_dir/share/zsh/site-functions"
            mv ./fd-*/autocomplete/fd.bash "$pkg_src_dir/share/bash-completion/completions/fd" 2>/dev/null || true
            mv ./fd-*/autocomplete/fd.fish "$pkg_src_dir/share/fish/vendor_completions.d/fd.fish" 2>/dev/null || true
            mv ./fd-*/autocomplete/_fd "$pkg_src_dir/share/zsh/site-functions/_fd" 2>/dev/null || true
        fi

        # install man page if present
        if test -f ./fd-*/fd.1; then
            mkdir -p "$pkg_src_dir/share/man/man1"
            mv ./fd-*/fd.1 "$pkg_src_dir/share/man/man1/fd.1"
        fi
    }
}

__init_fd
