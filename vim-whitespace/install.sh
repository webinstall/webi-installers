#!/bin/sh

__init_vim_whitespace() {
    set -e
    set -u

    mkdir -p "$HOME/.vim/plugins"
    rm -rf "$HOME/.vim/plugins/whitespace.vim"

    echo ""

    if [ ! -e "$HOME/.vimrc" ]; then
        touch "$HOME/.vimrc"
    fi

    if ! [ -f "$HOME/.vim/plugins/whitespace.vim" ]; then
        mkdir -p ~/.vim/plugins
        WEBI_HOST=${WEBI_HOST:-"https://webinstall.dev"}
        curl -fsS -o ~/.vim/plugins/whitespace.vim "$WEBI_HOST/packages/vim-whitespace/whitespace.vim"
    fi

    if ! grep 'source.*plugins.whitespace.vim' -r ~/.vimrc > /dev/null 2> /dev/null; then
        set +e
        mkdir -p ~/.vim/plugins
        printf '\n" Tab & Whitespace: reasonable defaults from webinstall.dev/vim-whitespace\n' >> ~/.vimrc
        printf 'source ~/.vim/plugins/whitespace.vim\n' >> ~/.vimrc
        set -e
        echo "added ~/.vim/plugins/whitespace.vim"
        echo "updated ~/.vimrc with 'source ~/.vim/plugins/whitespace.vim'"
        echo ""
    fi

    echo "Vim's has been updated with reasonable whitespace settings."
}

__init_vim_whitespace
