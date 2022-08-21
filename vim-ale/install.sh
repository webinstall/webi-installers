#!/bin/sh

#shellcheck disable=SC1003

__init_vim_ale() {
    set -e
    set -u

    mkdir -p "$HOME/.vim/pack/plugins/start"
    rm -rf "$HOME/.vim/pack/plugins/start/ale"
    git clone --depth=1 https://github.com/dense-analysis/ale.git "$HOME/.vim/pack/plugins/start/ale"

    if [ ! -f "$HOME/.vimrc" ]; then
        touch "$HOME/.vimrc"
    fi

    mkdir -p ~/.vim/plugins
    if ! [ -f "$HOME/.vim/plugins/ale.vim" ]; then
        WEBI_HOST=${WEBI_HOST:-"https://webinstall.dev"}
        curl -fsSL -o ~/.vim/plugins/ale.vim "$WEBI_HOST/packages/vim-ale/ale.vim"
    fi

    if ! grep 'source.*plugins.ale.vim' -r ~/.vimrc > /dev/null 2> /dev/null; then
        set +e
        mkdir -p ~/.vim/plugins
        printf '\n" ALE: reasonable defaults from webinstall.dev/vim-ale\n' >> ~/.vimrc
        printf 'source ~/.vim/plugins/ale.vim\n' >> ~/.vimrc
        set -e
        echo ""
        echo "add ~/.vim/plugins/ale.vim"
        echo "updated ~/.vimrc with 'source ~/.vim/plugins/ale.vim'"
    fi

    echo ""
    echo "vim-ale enabled with reasonable defaults"
    echo ""
    echo "note: don't forget to install the relevant linters and formatters, such as:"
    echo ''
    echo '    webi \'
    echo '        jshint \'
    echo '        prettier \'
    echo '        shellcheck \'
    echo '        shfmt \'
    echo ''

}

__init_vim_ale
