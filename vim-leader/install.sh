#!/bin/bash

__init_vim_leader() {
    set -e
    set -u

    mkdir -p "$HOME/.vim/plugins"
    rm -rf "$HOME/.vim/plugins/shell.vim"

    echo ""

    if [ ! -e "$HOME/.vimrc" ]; then
        touch "$HOME/.vimrc"
    fi

    if ! grep '^let mapleader =' -r ~/.vimrc >/dev/null 2>/dev/null; then
        rm -rf ~/.vimrc.new.1
        printf '" Set Leader to Space (with \\ and , as aliases) by webinstall.dev/vim-leader\n' >>~/.vimrc.new.1
        printf 'let mapleader = " "\n' >>~/.vimrc.new.1
        printf 'nmap <bslash> <space>\n' >>~/.vimrc.new.1
        printf 'nmap , <space>\n' >>~/.vimrc.new.1
        printf '\n' >>~/.vimrc.new.1
        cat ~/.vimrc >>~/.vimrc.new.1
        mv ~/.vimrc.new.1 ~/.vimrc
    fi

    echo ""
    echo "Vim Leader set to Space. Edit with 'vim ~/.vimrc'"
}

__init_vim_leader
