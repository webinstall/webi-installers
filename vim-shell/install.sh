#!/bin/sh

__init_vim_shell() {
    set -e
    set -u

    mkdir -p "$HOME/.vim/plugins"
    rm -rf "$HOME/.vim/plugins/shell.vim"

    echo ""

    if [ ! -e "$HOME/.vimrc" ]; then
        touch "$HOME/.vimrc"
    fi

    if ! grep -q 'shell=' ~/.vimrc 2> /dev/null; then
        b_shell='bash'
        if ! command -v bash > /dev/null; then
            b_shell='sh'
        fi
        {
            printf '" bash set as default shell (for compatibility) by webinstall.dev/vim-shell\n'
            printf 'set shell=%s\n' "${b_shell}"
            printf '\n'
            cat ~/.vimrc
        } >> ~/.vimrc.new.1
        mv ~/.vimrc.new.1 ~/.vimrc
    fi

    echo ""
    echo "Vim default shell is set. Edit with 'vim ~/.vimrc'"
}

__init_vim_shell
