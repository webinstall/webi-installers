#!/bin/sh

# shellcheck disable=SC2034
# "'pkg_cmd_name' appears unused. Verify it or export it."

__init_keychain() {
    set -e
    set -u

    ##################
    # Install keychain #
    ##################

    # Every package should define these 6 variables
    pkg_cmd_name="keychain"

    pkg_dst_cmd="$HOME/.local/bin/keychain"
    pkg_dst="$pkg_dst_cmd"

    pkg_src_cmd="$HOME/.local/opt/keychain-v$WEBI_VERSION/bin/keychain"
    pkg_src_dir="$HOME/.local/opt/keychain-v$WEBI_VERSION"
    pkg_src="$pkg_src_cmd"

    # pkg_install must be defined by every package
    pkg_install() {
        # ~/.local/opt/keychain-v0.99.9/bin
        mkdir -p "$(dirname "${pkg_src_cmd}")"

        # mv ./keychain-*/keychain ~/.local/opt/keychain-v0.99.9/bin/keychain
        mv ./keychain "${pkg_src_cmd}"
    }

    # pkg_get_current_version is recommended, but not required
    pkg_get_current_version() {
        # 'keychain --version' has output in this format:
        # <empty-line>
        # * keychain 2.8.5 ~ http://www.funtoo.org
        #
        #   Copyright 2002-2006 Gentoo Foundation;
        #   Copyright 2007 Aron Griffis;
        #   Copyright 2009-2017 Funtoo Solutions, Inc;
        #   lockfile() Copyright 2009 Parallels, Inc.
        #
        # Keychain is free software: you can redistribute it and/or modify
        # it under the terms of the GNU General Public License version 2 as
        # published by the Free Software Foundation.
        #
        # and is redirected to stderr
        # This trims it down to just the version number:
        #       2.8.5
        keychain --version 2>&1 |
            head -n 2 |
            tr -d '\n' |
            sed 's/^[[:space:]]*//;s/[[:space:]]*$//' |
            cut -d' ' -f3
    }

}

__init_keychain
