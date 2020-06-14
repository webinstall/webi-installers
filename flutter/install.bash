#!/bin/bash

# title: Flutter
# homepage: https://flutter.dev
# tagline: UI Toolkit for mobile, web, and desktop
# description: |
#   Flutter is Google’s UI toolkit for building beautiful, natively compiled applications for mobile, web, and desktop from a single codebase.
# examples: |
#
#   ```bash
#   flutter create my_app
#   ```

set -e
set -u

# NOTE: pkg_* variables can be defined here
#       pkg_cmd_name
#       pkg_new_opt, pkg_new_bin, pkg_new_cmd
#       pkg_common_opt, pkg_common_bin, pkg_common_cmd
#
# Their defaults are defined in webi/template.bash at https://github.com/webinstall/packages

pkg_cmd_name="flutter"

pkg_get_current_version() {
    # 'flutter --version' outputs a lot of information:
    #       Flutter 1.19.0-4.1.pre • channel beta • https://github.com/flutter/flutter.git
    #       Framework • revision f994b76974 (4 days ago) • 2020-06-09 15:53:13 -0700
    #       Engine • revision 9a28c3bcf4
    #       Tools • Dart 2.9.0 (build 2.9.0-14.1.beta)
    # This trims it down to just the version number:
    #       1.19.0-4.1.pre
    echo "$(flutter --version 2>/dev/null | head -n 1 | cut -d' ' -f2)"
}

pkg_link_new_version() {
    # 'pkg_common_opt' will default to $HOME/.local/opt/flutter
    # 'pkg_new_opt' will be the installed version, such as to $HOME/.local/opt/flutter-v1.17.3
    rm -rf "$pkg_common_opt"
    ln -s "$pkg_new_opt" "$pkg_common_opt"
}

pkg_pre_install() {
    # web_* are defined in webi/template.bash at https://github.com/webinstall/packages

    # multiple versions may be installed
    # if one already matches, it will simply be re-linked
    webi_check

    # the download is quite large - hopefully you have wget installed
    # will go to ~/Downloads by default
    webi_download

    # Multiple formats are supported: .xz, .tar.*, and .zip
    # will be extracted to $WEBI_TMP
    webi_extract
}

pkg_install() {
    pushd "$WEBI_TMP" 2>&1 >/dev/null

        # remove the versioned folder, just in case it's there with junk
        rm -rf "$pkg_new_opt"

        # rename the entire extracted folder to the new location
        # (this will be "$HOME/.local/opt/flutter-v$WEBI_VERSION" by default)
        mv ./flutter* "$pkg_new_opt"

    popd 2>&1 >/dev/null
}

pkg_post_install() {
    pkg_link_new_version

    # web_path_add is defined in webi/template.bash at https://github.com/webinstall/packages
    # Adds "$HOME/.local/opt/flutter" to PATH
    webi_path_add "$pkg_common_bin"
}
