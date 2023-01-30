#!/bin/sh

set -e
set -u

# NOTE: pkg_* variables can be defined here
#       pkg_cmd_name
#       pkg_src, pkg_src_bin, pkg_src_cmd
#       pkg_dst, pkg_dst_bin, pkg_dst_cmd
#
# Their defaults are defined in _webi/template.sh at https://github.com/webinstall/packages

# Every package should define these 6 variables
pkg_cmd_name="bun"

pkg_dst_cmd="$HOME/.local/opt/bun/bin/bun"
pkg_dst_dir="$HOME/.local/opt/bun"
pkg_dst="$pkg_dst_dir"

pkg_src_cmd="$HOME/.local/opt/bun-v$WEBI_VERSION/bin/bun"
pkg_src_dir="$HOME/.local/opt/bun-v$WEBI_VERSION"
pkg_src="$pkg_src_dir"

pkg_get_current_version() {
    # 'bun --version' only outputs the version:
    #       0.5.1
    # But we future-proof it a little anyway
    #       0.5.1
    bun --version 2> /dev/null | head -n 1 | cut -d' ' -f1
}

# pkg_install must be defined by every package
pkg_install() {
    # ~/.local/opt/bun-v0.5.1/bin
    mkdir -p "$(dirname "$pkg_src_cmd")"

    # mv ./bun-*/bun ~/.local/opt/bun-v0.5.1/bin/bun
    mv ./bun-*/bun* "$pkg_src_cmd"
}
