#!/bin/sh

# shellcheck disable=SC2034
# "'pkg_cmd_name' appears unused. Verify it or export it."

__init_hugoextended() {
    set -e
    set -u

    WEBI_SINGLE=true

    # Every package should define these 6 variables
    pkg_cmd_name="hugo"

    pkg_dst_cmd="$HOME/.local/bin/hugo"
    pkg_dst="$pkg_dst_cmd"

    pkg_src_cmd="$HOME/.local/opt/hugo-extended-v$WEBI_VERSION/bin/hugo"
    pkg_src_dir="$HOME/.local/opt/hugo-extended-v$WEBI_VERSION/bin"
    pkg_src="$pkg_src_dir"

    # pkg_install must be defined by every package
    pkg_install() {
        # ~/.local/opt/hugo-extended-v0.118.2/bin
        mkdir -p "$(dirname "${pkg_src_cmd}")"

        # mv ./hugo ~/.local/opt/hugo-extended-v0.118.2/bin/
        mv ./hugo "${pkg_src_cmd}"
    }

    pkg_get_current_version() {
        # 'hugo version' has output in this format:
        #       hugo v0.118.2-da7983ac4b94d97d776d7c2405040de97e95c03d darwin/arm64 BuildDate=2023-08-31T11:23:51Z VendorInfo=gohugoio
        # This trims it down to just the version number:
        #       0.118.2
        hugo version 2> /dev/null | head -n 1 | cut -d' ' -f2 | cut -d '-' -f1 | sed 's:^v::'
    }
}

__init_hugoextended
