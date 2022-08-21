#!/bin/sh

__init_vim_shfmt() {
    set -e
    set -u

    mkdir -p "$HOME/.vim/pack/plugins/start"
    rm -rf "$HOME/.vim/pack/plugins/start/vim-shfmt"
    git clone --depth=1 https://github.com/z0mbix/vim-shfmt.git "$HOME/.vim/pack/plugins/start/vim-shfmt"

    export PATH="$HOME/.local/bin:${PATH}"
    if [ -z "$(command -v shfmt)" ]; then
        "$HOME/.local/bin/webi" shfmt
    fi
    if [ -z "$(command -v shellcheck)" ]; then
        "$HOME/.local/bin/webi" shellcheck
    fi

    if [ ! -f "$HOME/.vimrc" ]; then
        touch "$HOME/.vimrc"
    fi

    mkdir -p ~/.vim/plugins
    if ! [ -f "$HOME/.vim/plugins/shfmt.vim" ]; then
        WEBI_HOST=${WEBI_HOST:-"https://webinstall.dev"}
        curl -fsSL -o ~/.vim/plugins/shfmt.vim "$WEBI_HOST/packages/vim-shfmt/shfmt.vim"
    fi

    if ! grep 'source.*plugins.shfmt.vim' -r ~/.vimrc > /dev/null 2> /dev/null; then
        set +e
        mkdir -p ~/.vim/plugins
        printf '\n" shfmt: reasonable defaults from webinstall.dev/vim-shfmt\n' >> ~/.vimrc
        printf 'source ~/.vim/plugins/shfmt.vim\n' >> ~/.vimrc
        set -e
        echo ""
        echo "add ~/.vim/plugins/shfmt.vim"
        echo "updated ~/.vimrc with 'source ~/.vim/plugins/shfmt.vim'"
    fi

    echo ""
    echo "vim-shfmt enabled with reasonable defaults"

}

__init_vim_shfmt
