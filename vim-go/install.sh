#!/bin/bash

{
    set -e
    set -u

    mkdir -p "$HOME/.vim/pack/plugins/start"
    rm -rf "$HOME/.vim/pack/plugins/start/vim-go"
    git clone --depth=1 https://github.com/fatih/vim-go.git "$HOME/.vim/pack/plugins/start/vim-go"

    # Install go linting tools
    echo "Building go language tools..."
    echo gopls
    go get golang.org/x/tools/gopls > /dev/null #2>/dev/null
    echo golint
    go get golang.org/x/lint/golint > /dev/null #2>/dev/null
    echo errcheck
    go get github.com/kisielk/errcheck > /dev/null #2>/dev/null
    echo goimports
    go get golang.org/x/tools/cmd/goimports > /dev/null #2>/dev/null
    echo goreturns
    go get github.com/sqs/goreturns > /dev/null #2>/dev/null

    if [ -f "$HOME/.vimrc" ]; then
        set +e
        if ! grep 'source.*go.vim' -r ~/.vimrc; then
            mkdir -p ~/.vim/plugin
            printf '\n" Golang: reasonable defaults from webinstall.dev/vim-go\n' >> ~/.vimrc
            printf 'source ~/.vim/plugin/go.vim\n' >> ~/.vimrc
        fi
        set -e
    fi

    if ! [ -f "$HOME/.vim/plugin/go.vim" ]; then
        mkdir -p ~/.vim/plugin
        WEBI_HOST=${WEBI_HOST:-"https://webinstall.dev"}
        curl -fsS -o ~/.vim/plugin/go.vim "$WEBI_HOST/packages/vim-go/go.vim"
    fi
}
