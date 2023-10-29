#!/bin/sh
set -e
set -u

fn_vim_init() { (
    if ! test -f ~/.vimrc; then
        touch ~/.vimrc
    fi

    mkdir -p ~/.vim/pack/plugins/start/
    mkdir -p ~/.vim/plugins/
); }

__install_vim_plugin() {

    # Non-executable packages should define these variables
    pkg_cmd_name="vim-commentary"
    pkg_no_exec=true
    pkg_dst="${HOME}/.vim/pack/plugins/start/vim-commentary"

    my_name="commentary"
    my_pkg_name="vim-commentary"
    my_note="${my_pkg_name}: installed via webinstall.dev/${my_pkg_name}"

    pkg_install() { (
        fn_vim_init

        rm -rf ~/.vim/pack/plugins/start/"${my_pkg_name}"/
        mv ./vim-commentary-*/ ~/.vim/pack/plugins/start/"${my_pkg_name}"
    ); }

    pkg_link() { (
        return 0
    ); }

    pkg_post_install() { (
        mkdir -p ~/.vim/plugins
        if [ -f ~/.vim/plugins/"${my_name}.vim" ]; then
            echo "Found ~/.vim/plugins/${my_name}.vim"
        else
            webi_download \
                "${WEBI_HOST}/packages/${my_pkg_name}/${my_name}.vim" \
                ~/.vim/plugins/"${my_name}.vim" \
                "${my_name}.vim"
        fi

        if ! grep "source.*plugins.${my_name}.vim" -r ~/.vimrc > /dev/null 2> /dev/null; then
            set +e
            printf '\n" %s\n' "${my_note}" >> ~/.vimrc
            printf 'source ~/.vim/plugins/%s.vim\n' "${my_name}" >> ~/.vimrc
            set -e
            echo "Updated ~/.vimrc to 'source ~/.vim/plugins/${my_name}.vim'"
        fi

        echo ""
    ); }
}

__install_vim_plugin
