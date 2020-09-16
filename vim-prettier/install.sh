#!/bin/bash

{
    set -e
    set -u

    mkdir -p "$HOME/.vim/pack/plugins/start"
    rm -rf "$HOME/.vim/pack/plugins/start/vim-prettier"
    git clone --depth=1 https://github.com/prettier/vim-prettier.git "$HOME/.vim/pack/plugins/start/vim-prettier"

    npm install -g prettier@2

    if [ -f "$HOME/.vimrc" ]; then
        set +e
        if ! grep 'source.*prettier.vim' -r ~/.vimrc; then
            mkdir -p ~/.vim/plugin
            printf '\n" Prettier: reasonable defaults from webinstall.dev/vim-prettier\n' >> ~/.vimrc
            printf 'source ~/.vim/plugin/prettier.vim\n' >> ~/.vimrc
        fi
        set -e
    fi

    if ! [ -f "$HOME/.vim/plugin/prettier.vim" ]; then
        mkdir -p ~/.vim/plugin
        WEBI_HOST=${WEBI_HOST:-"https://webinstall.dev"}
        curl -fsS -o ~/.vim/plugin/prettier.vim "$WEBI_HOST/packages/vim-prettier/prettier.vim"
    fi
}
