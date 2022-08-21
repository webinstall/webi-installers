#!/bin/sh

__init_vim_prettier() {
    set -e
    set -u

    mkdir -p "$HOME/.vim/pack/plugins/start"
    rm -rf "$HOME/.vim/pack/plugins/start/vim-prettier"
    git clone --depth=1 https://github.com/prettier/vim-prettier.git "$HOME/.vim/pack/plugins/start/vim-prettier"

    if [ -z "$(command -v node)" ]; then
        export PATH="$HOME/.local/opt/node/bin:$HOME/.local/bin:${PATH}"
        "$HOME/.local/bin/webi" node
    fi
    npm install -g prettier@2

    if [ ! -f "$HOME/.vimrc" ]; then
        touch "$HOME/.vimrc"
    fi

    if ! [ -f "$HOME/.vim/plugins/prettier.vim" ]; then
        mkdir -p ~/.vim/plugins
        WEBI_HOST=${WEBI_HOST:-"https://webinstall.dev"}
        curl -fsSL -o ~/.vim/plugins/prettier.vim "$WEBI_HOST/packages/vim-prettier/prettier.vim"
    fi

    if ! grep 'source.*plugins.prettier.vim' -r ~/.vimrc > /dev/null 2> /dev/null; then
        set +e
        mkdir -p ~/.vim/plugins
        printf '\n" Prettier: reasonable defaults from webinstall.dev/vim-prettier\n' >> ~/.vimrc
        printf 'source ~/.vim/plugins/prettier.vim\n' >> ~/.vimrc
        set -e
        echo ""
        echo "add ~/.vim/plugins/prettier.vim"
        echo "updated ~/.vimrc with 'source ~/.vim/plugins/prettier.vim'"
    fi

    echo ""
    echo "vim-prettier enabled with reasonable defaults"
}

__init_vim_prettier
