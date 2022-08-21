#!/bin/sh

__init_vim_viminfo() {
    set -e
    set -u

    mkdir -p "$HOME/.vim/plugins"
    rm -rf "$HOME/.vim/plugins/viminfo.vim"

    echo ""

    if [ ! -e "$HOME/.vimrc" ]; then
        touch "$HOME/.vimrc"
    fi

    if ! [ -f "$HOME/.vim/plugins/viminfo.vim" ]; then
        mkdir -p ~/.vim/plugins
        WEBI_HOST=${WEBI_HOST:-"https://webinstall.dev"}
        curl -fsS -o ~/.vim/plugins/viminfo.vim "$WEBI_HOST/packages/vim-viminfo/viminfo.vim"
    fi

    if ! grep 'source.*plugins.viminfo.vim' -r ~/.vimrc > /dev/null 2> /dev/null; then
        set +e
        mkdir -p ~/.vim/plugins
        printf '\n" Vim Info: reasonable defaults (buffers, history, etc) from webinstall.dev/vim-viminfo\n' >> ~/.vimrc
        printf 'source ~/.vim/plugins/viminfo.vim\n' >> ~/.vimrc
        set -e

        echo "added ~/.vim/plugins/viminfo.vim"
        echo "updated ~/.vimrc with 'source ~/.vim/plugins/viminfo.vim'"
        echo ""
    fi

    echo "vim-info enabled with reasonable defaults"
}

__init_vim_viminfo
