#!/bin/sh

__init_vim_mouse() {
    set -e
    set -u

    mkdir -p "$HOME/.vim/plugins"
    rm -rf "$HOME/.vim/plugins/mouse.vim"

    echo ""

    if [ ! -e "$HOME/.vimrc" ]; then
        touch "$HOME/.vimrc"
    fi

    if ! [ -f "$HOME/.vim/plugins/mouse.vim" ]; then
        mkdir -p ~/.vim/plugins
        WEBI_HOST=${WEBI_HOST:-"https://webinstall.dev"}
        curl -fsS -o ~/.vim/plugins/mouse.vim "$WEBI_HOST/packages/vim-mouse/mouse.vim"
    fi

    if ! grep 'source.*plugins.mouse.vim' -r ~/.vimrc > /dev/null 2> /dev/null; then
        set +e
        mkdir -p ~/.vim/plugins
        printf '\n" Mouse Support: reasonable defaults from webinstall.dev/vim-mouse\n' >> ~/.vimrc
        printf 'source ~/.vim/plugins/mouse.vim\n' >> ~/.vimrc
        set -e
        echo "added ~/.vim/plugins/mouse.vim"
        echo "updated ~/.vimrc with 'source ~/.vim/plugins/mouse.vim'"
        echo ""
    fi

    echo "vim-mouse enabled with reasonable defaults"
}

__init_vim_mouse
