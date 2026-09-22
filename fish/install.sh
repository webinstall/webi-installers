#!/bin/sh
set -e
set -u

if command -v fish > /dev/null; then
    if ! test -e ~/.config/fish/config.fish; then
        mkdir -p ~/.config/fish
        touch ~/.config/fish/config.fish
        chmod 0600 ~/.config/fish/config.fish
    fi
fi

################
# Install fish #
################

my_os=$(uname -s)

# Every package should define these 6 variables
# shellcheck disable=2034
pkg_cmd_name="fish"

pkg_dst_cmd="$HOME/.local/bin/fish"
# shellcheck disable=2034
pkg_dst="$pkg_dst_cmd"

pkg_src_cmd="$HOME/.local/opt/fish-v$WEBI_VERSION/bin/fish"
# shellcheck disable=2034
pkg_src_dir="$HOME/.local/opt/fish-v$WEBI_VERSION"
# shellcheck disable=2034
pkg_src="$pkg_src_cmd"

if test "Darwin" = "${my_os}"; then
    pkg_src_cmd="/Applications/fish.app/Contents/Resources/base/usr/local/bin/fish"
    # shellcheck disable=2034
    pkg_src="${pkg_src_cmd}"
fi

_linux_post_install() {
    if ! test -e "$HOME/.local/bin/fish"; then
        return 0
    fi

    echo ""
    echo "To set fish as your default shell, run:"
    echo "    chsh -s $HOME/.local/bin/fish"
    echo ""
}

_macos_post_install() {
    if ! test -e "$HOME/.local/bin/fish"; then
        return 0
    fi

    echo ""
    echo "Trying to set fish as the default shell..."
    echo ""
    # stop the caching of preferences
    killall cfprefsd

    # Set default Terminal.app shell to fish
    defaults write com.apple.Terminal "Shell" -string "$HOME/.local/bin/fish"
    echo "To set 'fish' as the default Terminal.app shell:"
    echo "    Terminal > Preferences > General > Shells open with:"
    echo "    $HOME/.local/bin/fish"
    echo ""

    # Set default iTerm2 shell to fish
    if test -e "$HOME/Library/Preferences/com.googlecode.iterm2.plist"; then
        /usr/libexec/PlistBuddy \
            -c "SET ':New Bookmarks:0:Custom Command' 'Custom Shell'" \
            "$HOME/Library/Preferences/com.googlecode.iterm2.plist"
        /usr/libexec/PlistBuddy \
            -c "SET ':New Bookmarks:0:Command' $HOME/.local/bin/fish" \
            "$HOME/Library/Preferences/com.googlecode.iterm2.plist"
        echo "To set 'fish' as the default iTerm2 shell:"
        echo "    iTerm2 > Preferences > Profiles > General > Command >"
        echo "    Custom Shell: $HOME/.local/bin/fish"
        echo ""
    fi

    killall cfprefsd
}

# always try to reset the default shells
if test "Darwin" = "${my_os}"; then
    _macos_post_install
fi

pkg_install() {
    if test "Darwin" = "${my_os}"; then
        rm -rf "/Applications/fish-v${WEBI_VERSION}.app"
        mv -f fish*.app "/Applications/fish-v${WEBI_VERSION}.app"
        rm -rf /Applications/fish.app
        mv "/Applications/fish-v${WEBI_VERSION}.app" "/Applications/fish.app"
        return 0
    fi

    mkdir -p "$pkg_src_dir/bin"
    mv fish "$pkg_src_dir/bin/"
}

pkg_link() {
    if test "Darwin" = "${my_os}"; then
        mkdir -p "$HOME/.local/bin"
        ln -sf /Applications/fish.app/Contents/Resources/base/usr/local/bin/fish "$HOME/.local/bin/fish"
        return 0
    fi

    rm -rf "$pkg_dst_cmd"
    ln -s "$pkg_src_cmd" "$pkg_dst_cmd"
}

pkg_post_install() {
    # don't skip what webi would do automatically
    webi_post_install

    # try again to update default shells, now that all files should exist
    if test "Darwin" = "${my_os}"; then
        _macos_post_install
    else
        _linux_post_install
    fi
    if ! test -e ~/.config/fish/config.fish; then
        mkdir -p ~/.config/fish
        touch ~/.config/fish/config.fish
        chmod 0600 ~/.config/fish/config.fish
    fi
}

# pkg_get_current_version is recommended, but (soon) not required
pkg_get_current_version() {
    # 'fish --version' has output in this format:
    #       fish, version 4.3.3
    # This trims it down to just the version number:
    #       4.3.3
    fish --version 2> /dev/null | head -n 1 | cut -d ' ' -f 3
}
