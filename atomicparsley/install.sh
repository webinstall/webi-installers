#!/bin/sh
set -e
set -u

__init_atomicparsley() {

    #########################
    # Install AtomicParsley #
    #########################

    WEBI_SINGLE=true

    # Every package should define these 6 variables
    pkg_cmd_name="AtomicParsley"

    pkg_dst_cmd="$HOME/.local/bin/AtomicParsley"
    pkg_dst="$pkg_dst_cmd"

    pkg_src_cmd="$HOME/.local/opt/AtomicParsley-v$WEBI_VERSION/bin/AtomicParsley"
    pkg_src_dir="$HOME/.local/opt/AtomicParsley-v$WEBI_VERSION"
    pkg_src="$pkg_src_cmd"

    # pkg_install must be defined by every package
    pkg_install() {
        # ~/.local/opt/AtomicParsley-v20221229.172126.0/bin
        mkdir -p "$(dirname "$pkg_src_cmd")"

        # mv ./AtomicParsley ~/.local/opt/AtomicParsley-v20221229.172126.0/bin/AtomicParsley
        mv ./"$pkg_cmd_name" "$pkg_src_cmd"
    }

    pkg_get_current_version() {
        # 'AtomicParsley --version' has output in this format:
        #       AtomicParsley version: 20221229.172126.0 d813aa6e0304ed3ab6d92f1ae96cd52b586181ec (utf8)
        # This trims it down to just the version number:
        #       20221229.172126.0
        AtomicParsley --version 2> /dev/null | head -n 1 | cut -d' ' -f3
    }
}

__init_atomicparsley
