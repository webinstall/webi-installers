#!/bin/sh

__init_vim_viminfo() {
    set -e
    set -u

    mkdir -p "$HOME/.config/vim/plugins"
    rm -rf "$HOME/.config/vim/plugins/viminfo.vim"

    # create XDG_DATA_HOME dir to keep vim related files such as viminfo
    if [ ! -d "$HOME/.local/share/vim" ]; then
        mkdir -p "$HOME/.local/share/vim"
    fi

    echo ""

    if [ ! -e "$HOME/.vimrc" ]; then
        touch "$HOME/.vimrc"
    fi

    if ! [ -f "$HOME/.config/vim/plugins/viminfo.vim" ]; then
        mkdir -p ~/.config/vim/plugins
        WEBI_HOST=${WEBI_HOST:-"https://webinstall.dev"}
        curl -fsS -o ~/.config/vim/plugins/viminfo.vim "$WEBI_HOST/packages/vim-viminfo/viminfo.vim"
    fi

    if ! grep 'source.*plugins.viminfo.vim' -r ~/.vimrc > /dev/null 2> /dev/null; then
        set +e
        mkdir -p ~/.config/vim/plugins
        printf '\n" Vim Info: reasonable defaults (buffers, history, etc) from webinstall.dev/vim-viminfo\n' >> ~/.vimrc
        printf 'source ~/.config/vim/plugins/viminfo.vim\n' >> ~/.vimrc
        set -e

        echo "added ~/.config/vim/plugins/viminfo.vim"
        echo "updated ~/.vimrc with 'source ~/.config/vim/plugins/viminfo.vim'"
        echo ""
    fi

    echo "vim-info enabled with reasonable defaults"
}

__init_vim_viminfo
