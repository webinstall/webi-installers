#!/bin/sh

__install_vim_plugin() { (
    set -e
    set -u

    my_name="commentary"
    my_pkg_name="vim-commentary"
    my_repo="https://github.com/tpope/vim-commentary.git"
    my_note="vim-commentary: installed via webinstall.dev/vim-commentary"
    my_installed_msg="${my_pkg_name} installed with example config"

    mkdir -p ~/.vim/pack/plugins/start
    rm -rf ~/.vim/pack/plugins/start/"${my_pkg_name}"
    git clone --depth=1 "${my_repo}" ~/.vim/pack/plugins/start/"${my_pkg_name}"

    if [ ! -f ~/.vimrc ]; then
        touch ~/.vimrc
    fi

    mkdir -p ~/.vim/plugins
    if ! [ -f ~/.vim/plugins/"${my_name}.vim" ]; then
        WEBI_HOST=${WEBI_HOST:-"https://webinstall.dev"}
        curl -fsSL -o ~/.vim/plugins/"${my_name}.vim" "$WEBI_HOST/packages/${my_pkg_name}/${my_name}.vim"
    fi

    if ! grep "source.*plugins.${my_name}.vim" -r ~/.vimrc > /dev/null 2> /dev/null; then
        set +e
        mkdir -p ~/.vim/plugins
        printf '\n" %s\n' "${my_note}" >> ~/.vimrc
        printf 'source ~/.vim/plugins/%s.vim\n' "${my_name}" >> ~/.vimrc
        set -e
        echo ""
        echo "add ~/.vim/plugins/${my_name}.vim"
        echo "updated ~/.vimrc with 'source ~/.vim/plugins/${my_name}.vim'"
    fi

    echo ""
    echo "${my_installed_msg}"

); }

__install_vim_plugin
