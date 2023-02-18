#!/bin/sh

#shellcheck disable=SC1003

__init_vim_ale() {
    set -e
    set -u

    repo="https://github.com/dense-analysis/ale.git"
    ale_folder="$HOME/.vim/pack/plugins/start/ale"
    latest_version="$(git -c 'versionsort.suffix=-' \
        ls-remote --tags --sort='v:refname' "$repo" |
        tail -n1 |
        sed 's/.*\///; s/\^{}//')"

    mkdir -p "$HOME/.vim/pack/plugins/start"
    rm -rf "$ale_folder"
    git clone -b "$latest_version" --depth=1 "$repo" "$ale_folder"

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
