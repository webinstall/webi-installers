#!/bin/sh

__init_vim_italics() {
    set -e
    set -u

    mkdir -p "$HOME/.vim/plugins"
    rm -rf "$HOME/.vim/plugins/italics.vim"

    echo ""

    if [ ! -e "$HOME/.vimrc" ]; then
        touch "$HOME/.vimrc"
    fi

    if ! [ -f "$HOME/.vim/plugins/italics.vim" ]; then
        mkdir -p ~/.vim/plugins
        WEBI_HOST=${WEBI_HOST:-"https://webinstall.dev"}
        curl -fsS -o ~/.vim/plugins/italics.vim "$WEBI_HOST/packages/vim-italics/italics.vim"
    fi

    if ! grep 'source.*plugins.italics.vim' -r ~/.vimrc > /dev/null 2> /dev/null; then
        set +e
        mkdir -p ~/.vim/plugins
        printf '\n" Vim Italics: underlines for italics from webinstall.dev/vim-italics\n' >> ~/.vimrc
        printf 'source ~/.vim/plugins/italics.vim\n' >> ~/.vimrc
        set -e
        echo "added ~/.vim/plugins/italics.vim"
        echo "updated ~/.vimrc with 'source ~/.vim/plugins/italics.vim'"
        echo ""
    fi

    echo "vim-italics enabled"
}

__init_vim_italics
