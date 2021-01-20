#!/bin/bash

{
    curl -L https://github.com/pyenv/pyenv-installer/raw/master/bin/pyenv-installer | bash
    if [ -n "`$SHELL -c 'echo $ZSH_VERSION'`" ]; then
        echo 'export PATH="$HOME/.pyenv/bin:$PATH"'>> ~/.zshrc
        echo 'eval "$(pyenv init -)"'>> ~/.zshrc
        echo 'eval "$(pyenv virtualenv-init -)"' >> ~/.zshrc
    else
        echo 'export PATH="$HOME/.pyenv/bin:$PATH"'>> ~/.bashrc
        echo 'eval "$(pyenv init -)"'>> ~/.bashrc
        echo 'eval "$(pyenv virtualenv-init -)"'>> ~/.bashrc
    fi
}
