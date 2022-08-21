#!/bin/sh

__init_vim_syntastic() {
    set -e
    set -u

    mkdir -p "$HOME/.vim/pack/plugins/start"
    rm -rf "$HOME/.vim/pack/plugins/start/vim-syntastic"
    git clone --depth=1 https://github.com/vim-syntastic/syntastic.git "$HOME/.vim/pack/plugins/start/vim-syntastic"
}

__init_vim_syntastic
