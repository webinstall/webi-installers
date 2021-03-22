#!/bin/bash

function __init_vim_sensible() {
    set -e
    set -u

    mkdir -p "$HOME/.vim/pack/plugins/start"
    rm -rf "$HOME/.vim/pack/plugins/start/sensible" "$HOME/.vim/pack/plugins/start/vim-sensible"
    git clone --depth=1 https://tpope.io/vim/sensible.git "$HOME/.vim/pack/plugins/start/vim-sensible"
}

__init_vim_sensible
