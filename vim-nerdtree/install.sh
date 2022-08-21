#!/bin/sh

__init_vim_nerdtree() {
    set -e
    set -u

    mkdir -p "$HOME/.vim/pack/plugins/start"
    rm -rf "$HOME/.vim/pack/plugins/start/nerdtree.vim"
    git clone --depth=1 https://github.com/preservim/nerdtree.git "$HOME/.vim/pack/plugins/start/nerdtree.vim"

    if [ ! -f "$HOME/.vimrc" ]; then
        touch "$HOME/.vimrc"
    fi

    mkdir -p ~/.vim/plugins
    if ! [ -f "$HOME/.vim/plugins/nerdtree.vim" ]; then
        WEBI_HOST=${WEBI_HOST:-"https://webinstall.dev"}
        curl -fsSL -o ~/.vim/plugins/nerdtree.vim "$WEBI_HOST/packages/vim-nerdtree/nerdtree.vim"
    fi

    if ! grep 'source.*plugins.nerdtree.vim' -r ~/.vimrc > /dev/null 2> /dev/null; then
        set +e
        mkdir -p ~/.vim/plugins
        printf '\n" NERDTree: reasonable defaults from webinstall.dev/vim-nerdtree\n' >> ~/.vimrc
        printf 'source ~/.vim/plugins/nerdtree.vim\n' >> ~/.vimrc
        set -e
        echo ""
        echo "add ~/.vim/plugins/nerdtree.vim"
        echo "updated ~/.vimrc with 'source ~/.vim/plugins/nerdtree.vim'"
    fi

    echo ""
    echo "vim-nerdtree enabled with reasonable defaults"

}

__init_vim_nerdtree
