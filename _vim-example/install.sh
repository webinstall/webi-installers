#!/bin/sh

__init_vim_example() {
    set -e
    set -u

    mkdir -p "$HOME/.vim/pack/plugins/start"
    rm -rf "$HOME/.vim/pack/plugins/start/example.vim"
    git clone --depth=1 https://github.com/CHANGEME/example.git "$HOME/.vim/pack/plugins/start/example"

    if [ ! -f "$HOME/.vimrc" ]; then
        touch "$HOME/.vimrc"
    fi

    mkdir -p ~/.vim/plugins
    if ! [ -f "$HOME/.vim/plugins/example.vim" ]; then
        WEBI_HOST=${WEBI_HOST:-"https://webinstall.dev"}
        curl -fsSL -o ~/.vim/plugins/example.vim "$WEBI_HOST/packages/vim-example/example.vim"
    fi

    if ! grep 'source.*plugins.example.vim' -r ~/.vimrc > /dev/null 2> /dev/null; then
        set +e
        mkdir -p ~/.vim/plugins
        printf '\n" example: reasonable defaults from webinstall.dev/vim-example\n' >> ~/.vimrc
        printf 'source ~/.vim/plugins/example.vim\n' >> ~/.vimrc
        set -e
        echo ""
        echo "add ~/.vim/plugins/example.vim"
        echo "updated ~/.vimrc with 'source ~/.vim/plugins/example.vim'"
    fi

    echo ""
    echo "vim-example enabled with reasonable defaults"

}

__init_vim_example
