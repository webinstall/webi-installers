#!/bin/sh

__init_vim_spell() {
    set -e
    set -u

    mkdir -p "$HOME/.vim/plugins"
    rm -rf "$HOME/.vim/plugins/spell.vim"

    echo ""

    if [ ! -e "$HOME/.vimrc" ]; then
        touch "$HOME/.vimrc"
    fi

    if ! [ -f "$HOME/.vim/plugins/spell.vim" ]; then
        mkdir -p ~/.vim/plugins
        WEBI_HOST=${WEBI_HOST:-"https://webinstall.dev"}
        curl -fsS -o ~/.vim/plugins/spell.vim "$WEBI_HOST/packages/vim-spell/spell.vim"
    fi

    if ! grep 'source.*plugins.spell.vim' -r ~/.vimrc > /dev/null 2> /dev/null; then
        set +e
        mkdir -p ~/.vim/plugins
        printf '\n" Spell Check: reasonable defaults from webinstall.dev/vim-spell\n' >> ~/.vimrc
        printf 'source ~/.vim/plugins/spell.vim\n' >> ~/.vimrc
        set -e
        echo "added ~/.vim/plugins/spell.vim"
        echo "updated ~/.vimrc with 'source ~/.vim/plugins/spell.vim'"
        echo ""
    fi

    echo "vim-spell enabled with reasonable defaults"
}

__init_vim_spell
