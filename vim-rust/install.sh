#!/bin/sh

__init_vim_rust() {
    set -e
    set -u

    mkdir -p "$HOME/.vim/pack/plugins/start"
    rm -rf "$HOME/.vim/pack/plugins/start/rust.vim"
    git clone --depth=1 https://github.com/rust-lang/rust.vim "$HOME/.vim/pack/plugins/start/rust.vim"

    if [ -f "$HOME/.vimrc" ]; then
        set +e
        if ! grep 'source.*rust.vim' -r ~/.vimrc; then
            mkdir -p ~/.vim/plugins
            printf '\n" Rust: reasonable defaults from webinstall.dev/vim-rust\n' >> ~/.vimrc
            printf 'source ~/.vim/plugins/rust.vim\n' >> ~/.vimrc
        fi
        set -e
    fi

    if ! [ -f "$HOME/.vim/plugins/rust.vim" ]; then
        mkdir -p ~/.vim/plugins
        WEBI_HOST=${WEBI_HOST:-"https://webinstall.dev"}
        curl -fsS -o ~/.vim/plugins/rust.vim "$WEBI_HOST/packages/vim-rust/rust.vim"
    fi
}

__init_vim_rust
