#!/bin/sh

__init_pyenv() {
    set -e
    set -u

    b_os="$(uname -s)"
    if test "${b_os}" = 'Darwin'; then
        if ! test -x /Library/Developer/CommandLineTools/usr/bin/git; then
            "$HOME/.local/bin/webi" commandlinetools
        fi
    fi

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

    if command -v zsh > /dev/null; then
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

    if command -v fish > /dev/null; then
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
    webi_path_add ~/.pyenv/bin

    mkdir -p ~/.pyenv/shims
    webi_path_add ~/.pyenv/shims

    echo "NOTE: You may also need to CLOSE and RE-OPEN your terminal for pyenv to take effect."
}

__init_pyenv
