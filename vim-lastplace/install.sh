#!/bin/sh

__init_vim_lastplace() {
    set -e
    set -u

    mkdir -p "$HOME/.vim/pack/plugins/start"
    rm -rf "$HOME/.vim/pack/plugins/start/vim-lastplace"
    git clone --depth=1 https://github.com/farmergreg/vim-lastplace.git "$HOME/.vim/pack/plugins/start/vim-lastplace"

    if [ ! -f "$HOME/.vimrc" ]; then
        touch "$HOME/.vimrc"
    fi

    mkdir -p ~/.vim/plugins
    if ! [ -f "$HOME/.vim/plugins/lastplace.vim" ]; then
        WEBI_HOST=${WEBI_HOST:-"https://webinstall.dev"}
        curl -fsSL -o ~/.vim/plugins/lastplace.vim "$WEBI_HOST/packages/vim-lastplace/lastplace.vim"
    fi

    if ! grep 'source.*plugins.lastplace.vim' -r ~/.vimrc > /dev/null 2> /dev/null; then
        set +e
        mkdir -p ~/.vim/plugins
        printf '\n" lastplace: explicit defaults from webinstall.dev/vim-lastplace\n' >> ~/.vimrc
        printf 'source ~/.vim/plugins/lastplace.vim\n' >> ~/.vimrc
        set -e
        echo ""
        echo "add ~/.vim/plugins/lastplace.vim"
        echo "updated ~/.vimrc with 'source ~/.vim/plugins/lastplace.vim'"
    fi

    echo ""
    echo "vim-lastplace enabled with explicit defaults"
}

__init_vim_lastplace
