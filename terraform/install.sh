#!/bin/sh
set -e
set -u

pkg_cmd_name="terraform"

WEBI_SINGLE=true

pkg_get_current_version() {
    terraform -v 2> /dev/null |
        head -n 1 |
        cut -d 'v' -f 2
}

pkg_install() {
    # $HOME/.local/bin/opt/terraform-v1.3.2/bin
    mkdir -p "$pkg_src_bin"

    # mv ./terraform* "$HOME/.local/opt/terraform-v1.3.2/bin/terraform"
    mv ./"$pkg_cmd_name"* "$pkg_src_cmd"

    # chmod a+x "$HOME/.local/opt/terraform-v1.3.2/bin/terraform"
    chmod a+x "$pkg_src_cmd"
}

pkg_link() {
    # rm -f "$HOME/.local/bin/terraform"
    rm -f "$pkg_dst_cmd"

    # ln -s "$HOME/.local/opt/terraform-v1.3.2/bin/terraform" "$HOME/.local/bin/terraform"
    ln -s "$pkg_src_cmd" "$pkg_dst_cmd"
}
