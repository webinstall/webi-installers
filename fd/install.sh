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
    }
}

__init_fd
