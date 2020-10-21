#!/bin/bash

{
    set -e
    set -u

    mkdir -p "$HOME/.vim/pack/plugins/start"
    rm -rf "$HOME/.vim/pack/plugins/start/vim-go"
    git clone --depth=1 https://github.com/fatih/vim-go.git "$HOME/.vim/pack/plugins/start/vim-go"

    # Install go linting tools
    echo "Building go language tools..."
    export GO111MODULE=on

    echo ""

    # Official Golang Tooling
    echo -n "golint: "
    go get golang.org/x/lint/golint@latest > /dev/null #2>/dev/null
    echo -n "gopls: "
    go get golang.org/x/tools/gopls@latest > /dev/null #2>/dev/null
    echo -n "guru: "
    go get golang.org/x/tools/cmd/guru@latest > /dev/null #2>/dev/null
    echo -n "goimports: "
    go get golang.org/x/tools/cmd/goimports@latest > /dev/null #2>/dev/null
    echo -n "gorename: "
    go get golang.org/x/tools/cmd/gorename@latest > /dev/null #2>/dev/null
    echo -n "gotype: "
    go get golang.org/x/tools/cmd/gotype@latest > /dev/null #2>/dev/null

    echo -n "golangci-lint: "
    go get github.com/golangci/golangci-lint/cmd/golangci-lint@latest > /dev/null #2>/dev/null

    # Community Tooling
    echo -n "fillstruct: "
    go get github.com/davidrjenni/reftools/cmd/fillstruct@master > /dev/null #2>/dev/null
    echo -n "godef: "
    go get github.com/rogpeppe/godef@master > /dev/null #2>/dev/null
    echo -n "motion: "
    go get github.com/fatih/motion@master > /dev/null #2>/dev/null
    echo -n "errcheck: "
    go get github.com/kisielk/errcheck > /dev/null #2>/dev/null
    echo -n "dlv: "
    go get github.com/go-delve/delve/cmd/dlv@master > /dev/null #2>/dev/null
    echo -n "iferr: "
    go get github.com/koron/iferr@master > /dev/null #2>/dev/null
    echo -n "impl: "
    go get github.com/josharian/impl@master > /dev/null #2>/dev/null
    echo -n "keyify: "
    go get honnef.co/go/tools/cmd/keyify@master > /dev/null #2>/dev/null
    echo -n "gomodifytags: "
    go get github.com/fatih/gomodifytags@master > /dev/null #2>/dev/null
    echo -n "asmfmt: "
    go get github.com/klauspost/asmfmt/cmd/asmfmt@master > /dev/null #2>/dev/null
    echo -n "gotags: "
    go get github.com/jstemmer/gotags > /dev/null #2>/dev/null

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

    echo 'Running :GoInstallBinaries in vim ...'
    printf ':GoInstallBinaries\n:q\n' | vim -e
}
