#!/bin/bash

set -e
set -u

{
    # Straight from https://brew.sh
    #/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install.sh)"

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
