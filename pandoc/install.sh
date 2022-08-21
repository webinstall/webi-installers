#!/bin/sh
set -e
set -u

__init_pandoc() {

    ###################
    # Install pandoc #
    ###################

    # Every package should define these 6 variables
    pkg_cmd_name="pandoc"

    pkg_dst_cmd="$HOME/.local/bin/pandoc"
    pkg_dst="$pkg_dst_cmd"

    pkg_src_cmd="$HOME/.local/opt/pandoc-v$WEBI_VERSION/bin/pandoc"
    pkg_src_dir="$HOME/.local/opt/pandoc-v$WEBI_VERSION"
    pkg_src="$pkg_src_cmd"

    # pkg_install must be defined by every package
    pkg_install() {
        # ~/.local/opt/pandoc-v2.10.1/bin
        mkdir -p "$(dirname "$pkg_src_cmd")"

        # mv ./pandoc-*/pandoc ~/.local/opt/pandoc-v2.10.1/bin/pandoc
        mv ./pandoc-*/bin/pandoc "$pkg_src_cmd"
    }

    # pkg_get_current_version is recommended, but (soon) not required
    pkg_get_current_version() {
        # 'pandoc --version' has output in this format:
        # pandoc 2.10.1
        # Compiled with pandoc-types 1.21, texmath 0.12.0.3, skylighting 0.8.5
        # Default user data directory: /home/sergi/.local/share/pandoc or /home/sergi/.pandoc
        # Copyright (C) 2006-2020 John MacFarlane
        # Web:  https://pandoc.org
        # This is free software; see the source for copying conditions.
        # There is no warranty, not even for merchantability or fitness
        # for a particular purpose.
        # This trims it down to just the version number:
        #       2.10.1
        pandoc --version 2> /dev/null | head -n 1 | cut -d ' ' -f 2
    }
}

__init_pandoc
