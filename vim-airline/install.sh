#!/bin/sh

__init_vim_airline() {
    set -e
    set -u

    mkdir -p "$HOME/.vim/pack/plugins/start"
    rm -rf "$HOME/.vim/pack/plugins/start/vim-airline"
    git clone --depth=1 https://github.com/vim-airline/vim-airline.git "$HOME/.vim/pack/plugins/start/vim-airline"

    if [ ! -f "$HOME/.vimrc" ]; then
        touch "$HOME/.vimrc"
    fi

    mkdir -p ~/.vim/plugins
    if ! [ -f "$HOME/.vim/plugins/airline.vim" ]; then
        WEBI_HOST=${WEBI_HOST:-"https://webinstall.dev"}
        curl -fsSL -o ~/.vim/plugins/airline.vim "$WEBI_HOST/packages/vim-airline/airline.vim"
    fi

    if ! grep 'source.*plugins.airline.vim' -r ~/.vimrc > /dev/null 2> /dev/null; then
        set +e
        mkdir -p ~/.vim/plugins
        printf '\n" vim-airline: reasonable defaults from webinstall.dev/vim-airline\n' >> ~/.vimrc
        printf 'source ~/.vim/plugins/airline.vim\n' >> ~/.vimrc
        set -e
        echo ""
        echo "add ~/.vim/plugins/airline.vim"
        echo "updated ~/.vimrc with 'source ~/.vim/plugins/airline.vim'"
    fi

    echo ""
    echo "vim-airline enabled with reasonable defaults"
}

__init_vim_airline
