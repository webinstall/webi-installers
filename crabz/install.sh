#!/bin/sh

# The generic functions - version checks, download, extract, etc - are here:
#   - https://github.com/webinstall/packages/branches/master/_webi/template.sh

set -e
set -u

pkg_cmd_name="crabz"

# IMPORTANT: this let's other functions know to expect this to be a single file
WEBI_SINGLE=true

# Every package should define these 6 variables
pkg_cmd_name="crabz"

pkg_dst_cmd="$HOME/.local/bin/crabz"
#pkg_dst="$pkg_dst_cmd"

pkg_src_cmd="$HOME/.local/opt/crabz-v$WEBI_VERSION/bin/crabz"
#pkg_src_dir="$HOME/.local/opt/crabz-v$WEBI_VERSION/bin"
#pkg_src="$pkg_src_cmd"

pkg_get_current_version() {
    # 'crabz version' has output in this format:
    #       crabz git:xxxxxxx
    # Since that's not sortable, this prints v0.0.0
    #       v0.0.0
    echo "v0.0.0"
}

pkg_install() {
    # $HOME/.local/opt/crabz-v0.3.5/bin
    mkdir -p "${pkg_src_bin}"

    # mv ./crabz* "$HOME/.local/opt/crabz-v0.3.5/bin/crabz"
    mv ./"${pkg_cmd_name}"* "${pkg_src_cmd}"

    # chmod a+x "$HOME/.local/opt/crabz-v0.3.5/bin/crabz"
    chmod a+x "${pkg_src_cmd}"
}

pkg_link() {
    # rm -f "$HOME/.local/bin/crabz"
    rm -f "${pkg_dst_cmd}"

    # ln -s "$HOME/.local/opt/crabz-v0.3.5/bin/crabz" "$HOME/.local/bin/crabz"
    ln -s "${pkg_src_cmd}" "${pkg_dst_cmd}"
}
