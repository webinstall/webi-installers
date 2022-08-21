#!/bin/sh

__init_vim_devicons() {
    set -e
    set -u

    mkdir -p "$HOME/.vim/pack/plugins/start"
    rm -rf "$HOME/.vim/pack/plugins/start/devicons.vim"
    git clone --depth=1 https://github.com/ryanoasis/vim-devicons.git "$HOME/.vim/pack/plugins/start/devicons.vim"

    if [ ! -f "$HOME/.vimrc" ]; then
        touch "$HOME/.vimrc"
    fi

    mkdir -p ~/.vim/plugins
    if ! [ -f "$HOME/.vim/plugins/devicons.vim" ]; then
        WEBI_HOST=${WEBI_HOST:-"https://webinstall.dev"}
        curl -fsSL -o ~/.vim/plugins/devicons.vim "$WEBI_HOST/packages/vim-devicons/devicons.vim"
    fi

    if ! grep 'source.*plugins.devicons.vim' -r ~/.vimrc > /dev/null 2> /dev/null; then
        set +e
        mkdir -p ~/.vim/plugins
        printf '\n" devicons: reasonable defaults from webinstall.dev/vim-devicons\n' >> ~/.vimrc
        printf 'source ~/.vim/plugins/devicons.vim\n' >> ~/.vimrc
        set -e
        echo ""
        echo "add ~/.vim/plugins/devicons.vim"
        echo "updated ~/.vimrc with 'source ~/.vim/plugins/devicons.vim'"
    fi

    echo ""
    echo "vim-devicons enabled (NOTE: you must also have https://webinstall.dev/nerdfont)"

}

__init_vim_devicons
