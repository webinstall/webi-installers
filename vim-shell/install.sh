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

    if ! grep 'shell=' -r ~/.vimrc > /dev/null 2> /dev/null; then
        {
            printf '" bash set as default shell (for compatibility) by webinstall.dev/vim-shell\n'
            printf 'set shell=bash\n'
            printf '\n'
            cat ~/.vimrc
        } >> ~/.vimrc.new.1
        mv ~/.vimrc.new.1 ~/.vimrc
    fi

    echo ""
    echo "Vim default shell is set. Edit with 'vim ~/.vimrc'"
}

__init_vim_shell
