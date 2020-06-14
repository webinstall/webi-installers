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

###################
# Install flutter #
###################

# The command name may be different from the package name
# (i.e. golang => go, rustlang => cargo, ripgrep => rg)
# Note: $HOME may contain special characters and should alway be quoted
pkg_cmd_name="flutter"
#pkg_cmd_name_formatted="flutter $WEBI_VERSION"

# Some of these directories may be the same
pkg_common_opt="$HOME/.local/opt/flutter"
pkg_common_bin="$HOME/.local/opt/flutter/bin"
pkg_common_cmd="$HOME/.local/opt/flutter/bin/flutter"
pkg_new_opt="$HOME/.local/opt/flutter-v$WEBI_VERSION"
pkg_new_bin="$HOME/.local/opt/flutter-v$WEBI_VERSION/bin"
pkg_new_cmd="$HOME/.local/opt/flutter-v$WEBI_VERSION/bin/flutter"
pkg_current_cmd=""

# The version info should be reduced to a sortable version, without any leading characters
# (i.e. v12.8.0 => 12.8.0, go1.14 => 1.14, 1.12.13+hotfix => 1.12.13+hotfix)
pkg_get_current_version() {
    echo "$(flutter --version 2>/dev/null | head -n 1 | cut -d' ' -f2)"
}

# Any version-related directories should be unlinked and relinked to the correct version
# (for example: 'go' is special and needs both $HOME/go and $HOME/.local/opt/go)
# (others like 'rg', 'hugo', and 'caddy' are single files that just get replaced)
pkg_switch_version() {
    rm -rf "$pkg_common_opt"
    ln -s "$pkg_new_opt" "$pkg_common_opt"
}

# Different packages represent the version in different ways
# ex: node v12.8.0 (leading 'v')
# ex: go1.14 (no space, nor trailing '.0's)
# ex: flutter 1.17.2 (plain)
pkg_format_cmd_version() {
    my_version=$1
    echo "$pkg_cmd_name $my_version"
}

pkg_install() {
    pushd "$WEBI_TMP" 2>&1 >/dev/null

        # simpler for single-binary commands
        #mv ./example*/bin/example "$HOME/.local/bin"

        # best for packages and toolchains
        if [ -n "$(command -v rsync 2>/dev/null | grep rsync)" ]; then
            rsync -Krl ./flutter*/ "$pkg_new_opt/" 2>/dev/null
        else
            cp -Hr ./flutter*/* "$pkg_new_opt/" 2>/dev/null
            cp -Hr ./flutter*/.* "$pkg_new_opt/" 2>/dev/null
        fi
        rm -rf ./flutter*
    popd 2>&1 >/dev/null
}

pkg_post_install() {
    webi_path_add "$pkg_common_bin"
}

#
# The webi_* functions are defined in webi/template.bash at https://github.com/webinstall/packages
#

# for packages that can have multiple versions
webi_check
# for packages that can be downloaded via links in ./releases.js
webi_download
# for single files or packaged directories (compressed or uncompressed)
# supported formats: .xz, .tar.*, and .zip
webi_extract

echo "Installing '$pkg_cmd_name' v$WEBI_VERSION as $pkg_new_cmd"

# for installing the tool
pkg_install
# for updating paths and installing companion tools
pkg_post_install
# for re-linking to a previously installed version
pkg_switch_version

echo "Installed '$pkg_cmd_name' v$WEBI_VERSION as $pkg_new_cmd"

echo ""
