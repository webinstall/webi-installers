#!/bin/sh
set -e
set -u

pkg_cmd_name="terraform"

WEBI_SINGLE=true

pkg_get_current_version() {
    # 'terraform -v' has output in this format:
    #       Terraform v1.6.1
    #       on linux_amd64
    # This trims it down to just the version number:
    #       1.6.1
    terraform -v 2> /dev/null |
        head -n 1 |
        cut -d' ' -f2 |
        cut -c2-
}

pkg_install() {
    # $HOME/.local/bin/opt/terraform-v1.6.1/bin
    mkdir -p "$pkg_src_bin"

    # mv ./terraform* "$HOME/.local/opt/terraform-v1.6.1/bin/terraform"
    mv ./"$pkg_cmd_name"* "$pkg_src_cmd"

    # chmod a+x "$HOME/.local/opt/terraform-v1.6.1/bin/terraform"
    chmod a+x "$pkg_src_cmd"
}

pkg_link() {
    # rm -f "$HOME/.local/bin/terraform"
    rm -f "$pkg_dst_cmd"

    # ln -s "$HOME/.local/opt/terraform-v1.6.1/bin/terraform" "$HOME/.local/bin/terraform"
    ln -s "$pkg_src_cmd" "$pkg_dst_cmd"
}
