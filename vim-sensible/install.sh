#!/bin/bash

function __init_vim_sensible() {
    set -e
    set -u

    mkdir -p "$HOME/.vim/pack/plugins/start"
    rm -rf "$HOME/.vim/pack/plugins/start/sensible" "$HOME/.vim/pack/plugins/start/vim-sensible"

    # Note: we've had resolution issues in the past, and it doesn't seem likely
    #       that tpope will switch from using GitHub as the primary host, so we
    #       skip the redirect and use GitHub directly.
    #       Open to changing this back in the future.
    #my_sensible_repo="https://tpope.io/vim/sensible.git"
    my_sensible_repo="https://github.com/tpope/vim-sensible.git"
    git clone --depth=1 "${my_sensible_repo}" "$HOME/.vim/pack/plugins/start/vim-sensible"
}

__init_vim_sensible
