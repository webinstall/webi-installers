#!/bin/bash

set -e
set -u

function _install_brew() {
    # Straight from https://brew.sh
    #/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install.sh)"

    if [[ -n "$(uname -a | grep -i darwin)" ]]; then
        needs_xcode="$(/usr/bin/xcode-select -p > /dev/null 2> /dev/null || echo "true")"
        if [[ -n ${needs_xcode} ]]; then
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
        if [ -z "$(command -v gcc)" ]; then
            echo >&2 "Warning: to install 'gcc' et al on Linux use the built-in package manager."
            echo >&2 "       For example, try: sudo apt install -y build-essential"
        fi
        if [ -z "$(command -v git)" ]; then
            echo >&2 "Error: to install 'git' on Linux use the built-in package manager."
            echo >&2 "       For example, try: sudo apt install -y git"
            exit 1
        fi
    fi

    # From Straight from https://brew.sh
    if ! [ -d "$HOME/.local/opt/brew" ]; then
        echo "Installing to '$HOME/.local/opt/brew'"
        echo ""
        echo "If you prefer to have brew installed to '/usr/local' cancel now and do the following:"
        echo "        rm -rf '$HOME/.local/opt/brew'"
        echo '        /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install.sh)"'
        echo ""
        sleep 3
        git clone --depth=1 https://github.com/Homebrew/brew "$HOME/.local/opt/brew"
    fi

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
    echo '        /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install.sh)"'
    echo ""
}

_install_brew
