#!/bin/bash

__init_pyenv() {
    set -e
    set -u

    curl -fsSL https://github.com/pyenv/pyenv-installer/raw/master/bin/pyenv-installer | bash

    if [ ! -f ~/.bashrc ] || [ -z "$(grep 'pyenv init' ~/.bashrc)" ]; then
        echo '' >>~/.bashrc
        echo '# added by Webi for pyenv' >>~/.bashrc
        echo 'eval "$(pyenv init -)"' >>~/.bashrc
        echo 'eval "$(pyenv virtualenv-init -)"' >>~/.bashrc
    fi

    if [ -n "$(command -v zsh)" ]; then
        touch ~/.zshrc
        if [ -z "$(grep 'pyenv init' ~/.zshrc)" ]; then
            echo '' >>~/.zshrc
            echo '# added by Webi for pyenv' >>~/.zshrc
            echo 'eval "$(pyenv init -)"' >>~/.zshrc
            echo 'eval "$(pyenv virtualenv-init -)"' >>~/.zshrc
        fi
    fi

    if [ -n "$(command -v fish)" ]; then
        mkdir -p ~/.config/fish
        touch ~/.config/fish/config.fish
        if [ -z "$(grep 'pyenv init' ~/.config/fish/config.fish)" ]; then
            echo '' >>~/.config/fish/config.fish
            echo '# added by Webi for pyenv' >>~/.config/fish/config.fish
            echo 'status is-login; and pyenv init --path | source' >>~/.config/fish/config.fish
            echo 'status is-interactive; and pyenv init - | source' >>~/.config/fish/config.fish
        fi
    fi

    mkdir -p ~/.pyenv/bin
    pathman add ~/.pyenv/bin

    mkdir -p ~/.pyenv/shims
    pathman add ~/.pyenv/shims

    echo "NOTE: You may also need to CLOSE and RE-OPEN your terminal for pyenv to take effect."
}

__init_pyenv
