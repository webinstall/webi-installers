#!/bin/sh
set -e
set -u

if command -v fish > /dev/null; then
    if ! test -r ~/.config/fish/config.fish; then
        mkdir -p ~/.config/fish
        touch ~/.config/fish/config.fish
        chmod 0600 ~/.config/fish/config.fish
    fi
else
    if command -v sudo > /dev/null; then
        my_answer='n'
        if command -v apt > /dev/null; then
            echo ""
            echo "ERROR"
            echo "    No Webi installer for fish on Linux yet."
            echo ""
            echo "SOLUTION"
            echo "    Would you like to install with apt?"
            echo "    sudo apt install -y fish"
            echo ""
            printf "Install with sudo and apt [Y/n]? "
        elif command -v apk > /dev/null; then
            echo ""
            echo "ERROR"
            echo "    No Webi installer for fish on Alpine yet."
            echo ""
            echo "SOLUTION"
            echo "    Would you like to install with apk?"
            echo "    sudo apk add --no-cache fish"
            echo ""
            printf "Install with sudo and apk [Y/n]? "
        elif test "Darwin" != "$(uname -s)"; then
            echo "No fish installer for Linux yet."
            exit 1
        fi

        read -r my_answer < /dev/tty
        if test -z "${my_answer}" ||
            test "${my_answer}" = "Y" ||
            test "${my_answer}" = "y"; then
            sudo apt install -y fish
        else
            exit 1
        fi
    elif test "Darwin" != "$(uname -s)"; then
        echo "No fish installer for Linux yet."
        exit 1
    fi
fi

################
# Install fish #
################

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

# pkg_install must be defined by every package

_macos_post_install() {
    if test "Darwin" != "$(uname -s)"; then
        return 0
    fi

    if ! [ -e "$HOME/.local/bin/fish" ]; then
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
    if [ -e "$HOME/Library/Preferences/com.googlecode.iterm2.plist" ]; then
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

if test "Darwin" = "$(uname -s)"; then
    # always try to reset the default shells
    _macos_post_install
fi

pkg_install() {
    mv fish.app/Contents/Resources/base/usr/local "$HOME/.local/opt/fish-v${WEBI_VERSION}"

}

pkg_post_install() {
    # don't skip what webi would do automatically
    webi_post_install

    # try again to update default shells, now that all files should exist
    if test "Darwin" = "$(uname -s)"; then
        # always try to reset the default shells
        _macos_post_install
    fi

    if [ ! -e ~/.config/fish/config.fish ]; then
        mkdir -p ~/.config/fish
        touch ~/.config/fish/config.fish
        chmod 0600 ~/.config/fish/config.fish
    fi
}

# pkg_get_current_version is recommended, but (soon) not required
pkg_get_current_version() {
    # 'fish --version' has output in this format:
    #       fish, version 3.1.2
    # This trims it down to just the version number:
    #       3.1.2
    fish --version 2> /dev/null | head -n 1 | cut -d ' ' -f 3
}
