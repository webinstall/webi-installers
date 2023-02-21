#!/bin/sh

__init_vim_smartcase() {
    set -e
    set -u

    mkdir -p "$HOME/.vim/plugins"
    rm -rf "$HOME/.vim/plugins/smartcase.vim"

    echo ""

    if [ ! -e "$HOME/.vimrc" ]; then
        touch "$HOME/.vimrc"
    fi

    if ! [ -f "$HOME/.vim/plugins/smartcase.vim" ]; then
        mkdir -p ~/.vim/plugins
        WEBI_HOST=${WEBI_HOST:-"https://webinstall.dev"}
        curl -fsS -o ~/.vim/plugins/smartcase.vim "$WEBI_HOST/packages/vim-smartcase/smartcase.vim"
    fi

    if ! grep 'source.*plugins.smartcase.vim' -r ~/.vimrc > /dev/null 2> /dev/null; then
        set +e
        mkdir -p ~/.vim/plugins
        printf '\n" Smart Case: reasonable defaults from webinstall.dev/vim-smartcase\n' >> ~/.vimrc
        printf 'source ~/.vim/plugins/smartcase.vim\n' >> ~/.vimrc
        set -e
        echo "added ~/.vim/plugins/smartcase.vim"
        echo "updated ~/.vimrc with 'source ~/.vim/plugins/smartcase.vim'"
        echo ""
    fi

    echo "vim-smartcase enabled with reasonable defaults"
}

__init_vim_smartcase
