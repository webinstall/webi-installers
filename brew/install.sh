#!/bin/sh

set -e
set -u

_install_brew() {
    # Straight from https://brew.sh
    #/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install.sh)"

    if test "Darwin" = "$(uname -s)"; then
        needs_xcode="$(/usr/bin/xcode-select -p > /dev/null 2> /dev/null || echo "true")"
        if test -n "${needs_xcode}"; then
            echo ""
            echo ""
            echo "ERROR: Run this command to install XCode Command Line Tools first:"
            echo ""
            echo "    xcode-select --install"
            echo ""
            echo "After the install, close this terminal, open a new one, and try again."
            echo ""
        fi
    else
        if ! command -v gcc > /dev/null; then
            echo >&2 "Warning: to install 'gcc' et al on Linux use the built-in package manager."
            echo >&2 "       For example, try: sudo apt install -y build-essential"
        fi
        if ! command -v git > /dev/null; then
            echo >&2 "Error: to install 'git' on Linux use the built-in package manager."
            echo >&2 "       For example, try: sudo apt install -y git"
            exit 1
        fi
    fi

    # From Straight from https://brew.sh
    if ! test -d "$HOME/.local/opt/brew"; then
        echo "Installing to '$HOME/.local/opt/brew'"
        echo ""
        echo "If you prefer to have brew installed to '/usr/local' cancel now and do the following:"
        echo "        rm -rf '$HOME/.local/opt/brew'"
        # shellcheck disable=2016
        echo '        /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install.sh)"'
        echo ""
        sleep 3
        git clone --depth=1 https://github.com/Homebrew/brew "$HOME/.local/opt/brew"
    fi

    rm -rf "$HOME/.local/bin/brew-update-service-install"
    webi_download \
        "$WEBI_HOST/packages/brew/brew-update-service-install" \
        "$HOME/.local/bin/brew-update-service-install" \
        brew-update-service-install
    chmod a+x "$HOME/.local/bin/brew-update-service-install"

    webi_path_add "$HOME/.local/opt/brew/bin"
    export PATH="$HOME/.local/opt/brew/bin:$PATH"

    echo "Updating brew..."
    brew update

    webi_path_add "$HOME/.local/opt/brew/sbin"
    export PATH="$HOME/.local/opt/brew/sbin:$PATH"

    echo "Installed 'brew' to '$HOME/.local/opt/brew'"
    echo ""
    echo "If you prefer to have brew installed to '/usr/local' do the following:"
    echo "        mv '$HOME/.local/opt/brew' '$HOME/.local/opt/brew.$(date '+%F_%H-%M-%S').bak'"
    # shellcheck disable=2016
    echo '        /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install.sh)"'
    echo ""

    echo "To register 'brew update' as a hourly system service:"
    echo "        brew-update-service-install"
    echo ""
}

_install_brew
