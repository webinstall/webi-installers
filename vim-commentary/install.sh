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
    # ~/.vim/plugins/<vim-name>.vim
    my_vim_confname="commentary.vim"

    # ~/.vim/pack/plugins/start/<vim-plugin>/
    my_vim_plugin="vim-commentary"

    # as opposed to PKG_NAME-<version> / WEBI_PKG_PATHNAME:
    # ~/Downloads/webi/<PKG_NAME>-<version>/

    # Non-executable packages should define these variables
    pkg_cmd_name="${my_vim_plugin}"
    pkg_no_exec=true
    pkg_dst="${HOME}/.vim/pack/plugins/start/${my_vim_plugin}"

    pkg_install() { (
        fn_vim_init

        rm -rf ~/.vim/pack/plugins/start/"${my_vim_plugin}"/
        mv ./"${WEBI_PKG_PATHNAME}"/ ~/.vim/pack/plugins/start/"${my_vim_plugin}"
    ); }

    pkg_post_install() { (
        mkdir -p ~/.vim/plugins
        if [ -f ~/.vim/plugins/"${my_vim_confname}" ]; then
            echo "Found ~/.vim/plugins/${my_vim_confname}"
        else
            webi_download \
                "${WEBI_HOST}/packages/${PKG_NAME}/${my_vim_confname}" \
                ~/.vim/plugins/"${my_vim_confname}" \
                "${my_vim_confname}"
        fi

        if ! grep "source.*plugins.${my_vim_confname}" -r ~/.vimrc > /dev/null 2> /dev/null; then
            my_note="${my_vim_plugin}: installed via webinstall.dev/${PKG_NAME}"
            set +e
            printf '\n" %s\n' "${my_note}" >> ~/.vimrc
            printf 'source ~/.vim/plugins/%s\n' "${my_vim_confname}" >> ~/.vimrc
            set -e
            echo "Updated ~/.vimrc to 'source ~/.vim/plugins/${my_vim_confname}'"
        fi

        echo ""
    ); }
}

__install_vim_plugin
