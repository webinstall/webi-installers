#!/bin/sh

__init_pyenv() {
    set -e
    set -u

    curl -fsSL https://github.com/pyenv/pyenv-installer/raw/master/bin/pyenv-installer | bash

    if [ ! -f ~/.bashrc ] || ! grep -q 'pyenv init' ~/.bashrc; then
        {
            echo ''
            echo '# added by Webi for pyenv'
            # shellcheck disable=2016
            echo 'eval "$(pyenv init -)"'
            # shellcheck disable=2016
            echo 'eval "$(pyenv virtualenv-init -)"'
        } >> ~/.bashrc
    fi

    if [ -n "$(command -v zsh)" ]; then
        touch ~/.zshrc
        if ! grep -q 'pyenv init' ~/.zshrc; then
            {
                echo ''
                echo '# added by Webi for pyenv'
                # shellcheck disable=2016
                echo 'eval "$(pyenv init -)"'
                # shellcheck disable=2016
                echo 'eval "$(pyenv virtualenv-init -)"'
            } >> ~/.zshrc
        fi
    fi

    if [ -n "$(command -v fish)" ]; then
        mkdir -p ~/.config/fish
        touch ~/.config/fish/config.fish
        if ! grep -q 'pyenv init' ~/.config/fish/config.fish; then
            {
                echo ''
                echo '# added by Webi for pyenv'
                echo 'status is-login; and pyenv init --path | source'
                echo 'status is-interactive; and pyenv init - | source'
            } >> ~/.config/fish/config.fish
        fi
    fi

    mkdir -p ~/.pyenv/bin
    pathman add ~/.pyenv/bin

    mkdir -p ~/.pyenv/shims
    pathman add ~/.pyenv/shims

    echo "NOTE: You may also need to CLOSE and RE-OPEN your terminal for pyenv to take effect."
}

__init_pyenv
