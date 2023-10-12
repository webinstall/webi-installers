#!/bin/sh

__init_vim_airline_themes() {
    set -e
    set -u

    mkdir -p "$HOME/.vim/pack/plugins/start"
    rm -rf "$HOME/.vim/pack/plugins/start/vim-airline-themes"
    git clone --depth=1 https://github.com/vim-airline/vim-airline-themes.git "$HOME/.vim/pack/plugins/start/vim-airline-themes"

    if [ ! -f "$HOME/.vimrc" ]; then
        touch "$HOME/.vimrc"
    fi

    mkdir -p ~/.vim/plugins
    if [ -f "$HOME/.vim/plugins/airline.vim" ]; then
        WEBI_HOST=${WEBI_HOST:-"https://webinstall.dev"}
        if ! grep -qF "let g:airline_theme=" "$HOME/.vim/plugins/airline.vim"; then
            echo ""
            echo "set theme 'simple' as default, update in $HOME/.vim/plugins/airline.vim"
            curl -s "$WEBI_HOST/packages/vim-airline-themes/airline.vim" >> "$HOME/.vim/plugins/airline.vim"
        fi
    else
        curl -fsSL -o ~/.vim/plugins/airline.vim "$WEBI_HOST/packages/vim-airline-themes/airline.vim"
    fi

    if ! grep 'source.*plugins.airline.vim' -r ~/.vimrc > /dev/null 2> /dev/null; then
        set +e
        mkdir -p ~/.vim/plugins
        printf '\n" vim-airline-themes: reasonable defaults from webinstall.dev/vim-airline-themes\n' >> ~/.vimrc
        printf 'source ~/.vim/plugins/airline.vim\n' >> ~/.vimrc
        set -e
        echo ""
        echo "add ~/.vim/plugins/airline.vim"
        echo "updated ~/.vimrc with 'source ~/.vim/plugins/airline.vim'"
    fi

    echo ""
    echo "vim-airline-themes enabled with reasonable defaults"
}

__init_vim_airline_themes
