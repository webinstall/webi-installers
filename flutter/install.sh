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
pkg_cmd_name="flutter"

pkg_dst_cmd="$HOME/.local/opt/flutter/bin/flutter"
pkg_dst_dir="$HOME/.local/opt/flutter"
pkg_dst="$pkg_dst_dir"

pkg_src_cmd="$HOME/.local/opt/flutter-v$WEBI_VERSION/bin/flutter"
pkg_src_dir="$HOME/.local/opt/flutter-v$WEBI_VERSION"
pkg_src="$pkg_src_dir"

pkg_get_current_version() {
    # 'flutter --version' outputs a lot of information:
    #       Flutter 1.19.0-4.1.pre • channel beta • https://github.com/flutter/flutter.git
    #       Framework • revision f994b76974 (4 days ago) • 2020-06-09 15:53:13 -0700
    #       Engine • revision 9a28c3bcf4
    #       Tools • Dart 2.9.0 (build 2.9.0-14.1.beta)
    # This trims it down to just the version number:
    #       1.19.0-4.1.pre
    flutter --version 2> /dev/null | head -n 1 | cut -d' ' -f2
}

pkg_format_cmd_version() {
    # 'flutter 1.19.0' is the canonical version format for flutter
    my_version="$1"
    echo "$pkg_cmd_name $my_version"
}
