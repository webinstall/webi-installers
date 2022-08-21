#!/bin/sh
set -e
set -u

__init_vim_beyondcode() {
    # mostly lightweight, or essential
    "$HOME/.local/bin/webi" \
        vim-leader \
        vim-shell \
        vim-sensible \
        vim-viminfo \
        vim-lastplace \
        vim-spell \
        vim-ale \
        vim-prettier \
        vim-whitespace

    # requires special hardware (mouse) or software (nerdfont)
    "$HOME/.local/bin/webi" \
        vim-gui \
        vim-nerdtree \
        nerdfont \
        vim-devicons

    if [ -n "$(command -v go)" ]; then
        "$HOME/.local/bin/webi" vim-go
    fi
    # done
}

__init_vim_beyondcode
