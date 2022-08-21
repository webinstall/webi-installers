#!/bin/sh

__init_vim_go() {
    set -e
    set -u

    mkdir -p "$HOME/.vim/pack/plugins/start"
    rm -rf "$HOME/.vim/pack/plugins/start/vim-go"
    git clone --depth=1 https://github.com/fatih/vim-go.git "$HOME/.vim/pack/plugins/start/vim-go"

    if [ -f "$HOME/.vimrc" ]; then
        set +e
        if ! grep 'source.*go.vim' -r ~/.vimrc; then
            mkdir -p ~/.vim/plugins
            printf '\n" Golang: reasonable defaults from webinstall.dev/vim-go\n' >> ~/.vimrc
            printf 'source ~/.vim/plugins/go.vim\n' >> ~/.vimrc
        fi
        set -e
    fi

    if ! [ -f "$HOME/.vim/plugins/go.vim" ]; then
        mkdir -p ~/.vim/plugins
        WEBI_HOST=${WEBI_HOST:-"https://webinstall.dev"}
        curl -fsS -o ~/.vim/plugins/go.vim "$WEBI_HOST/packages/vim-go/go.vim"
    fi

    export GO111MODULE=on
    echo ""
    echo 'Running :GoInstallBinaries in vim ...'
    echo '(this may take several minutes)'
    printf ':GoInstallBinaries\n:q\n' | vim -e
}

__init_vim_go
