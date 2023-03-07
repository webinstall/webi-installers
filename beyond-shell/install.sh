#!/bin/sh
set -e
set -u

webi_cmd="$HOME/.local/bin/webi"
aliasman_cmd="$HOME/.local/bin/aliasman"
pathman_cmd="$HOME/.local/bin/pathman"

my_date="$(
    date -u '+%F_%H.%M.%S'
)"
my_log="${HOME}/.local/share/beyond-code/var/${my_date}.log"

fn_node_version() { (
    my_node="${1:-}"

    if test -n "${my_node}"; then
        "${my_node}" --version | sed 's/v//'
    fi
); }

fn_node_path() { (
    if command -v node; then
        return 0
    fi

    if test ! -e ~/.local/opt/node/bin/node; then
        return 0
    fi

    echo ~/.local/opt/node/bin/node
); }

fn_node_install() { (
    node_minimum="18"

    my_path_actual="$(
        fn_node_path
    )"
    my_node="$(
        fn_node_path
    )"
    my_node_version="$(
        fn_node_version "${my_node}"
    )"

    if test -n "${my_path_actual}"; then
        my_bin_dir="$(
            dirname "${my_node}"
        )"
        my_node_dir="$(
            dirname "${my_bin_dir}"
        )"
        my_lib_dir="${my_node_dir}/lib/node_modules"
        if test ! -w "${my_bin_dir}" ||
            test ! -w "${my_node_dir}" ||
            test ! -w "${my_lib_dir}"; then
            printf "\e[31m[Warning]\e[0m \e[32mNode.js\e[0m at %s is not user-writable\n" "${my_path_actual}"
            sleep 1

            my_path_actual=""
        fi
    fi

    if test -n "${my_path_actual}"; then
        my_node_major="$(
            echo "${my_node_version}" | cut -d'.' -f1
        )"
        if test -z "${my_node_major}"; then
            my_path_actual=""
        elif test "${my_node_major}" -lt "${node_minimum}"; then

            printf "\e[31m[Warning]\e[0m \e[32mNode.js v%s\e[0m is too old\n" "${my_node_version}"
            sleep 1

            my_path_actual=""
        fi
    fi

    if test -z "${my_path_actual}"; then
        printf "\e[32m[Fixup]\e[0m Installing \e[32mNode.js\e[0m to \e[34m%s\e[0m\n" '~'/.local/opt/node/
        sleep 1

        "${webi_cmd}" node@lts >> "${my_log}"
        if test -e ~/.local/opt/node/bin/node; then
            "${pathman_cmd}" add ~/.local/opt/node/bin/ > /dev/null 2> /dev/null
        fi
    else
        echo "[Info] Found ${my_path_actual}/node (v${my_node_version})"
    fi
); }

fn_git_install() { (
    if [ "Darwin" = "$(uname -s)" ]; then
        needs_xcode="$(
            /usr/bin/xcode-select -p > /dev/null 2> /dev/null || echo "true"
        )"
        if [ -n "${needs_xcode}" ]; then
            echo ""
            echo ""
            printf "\e[31m[Error]\e[0m: Run this command to install XCode Command Line Tools first:\n"
            echo ""
            echo "    xcode-select --install"
            echo ""
            echo "After the install, close this terminal, open a new one, and try again."
            echo ""
            exit 1
        else
            my_git="$(command -v git)"
            echo "[Info] Found ${my_git}"
        fi
        return 0
    fi

    if ! command -v git > /dev/null; then
        fn_apt_get git git
        return 0
    fi

    my_git="$(command -v git)"
    echo "[Info] Found ${my_git}"
); }

fn_apt_get() { (
    my_cmd="${1:-}"
    my_pkg="${2:-}"

    printf "\e[31m[Warning]\e[0m \e[32m%s\e[0m not found\n" "${my_cmd}"

    printf "\e[32m[Fixup]\e[0m install \e[34m%s\e[0m (may require password)\n" "${my_pkg}"
    sleep 1

    echo "sudo apt-get install ${my_pkg}"

    # shellcheck disable=SC2030
    export DEBIAN_FRONTEND=noninteractive
    if ! sudo apt-get install -qq -y -o=Dpkg::Use-Pty=0 "${my_pkg}"; then
        echo "failed to install ${my_cmd} on"
        cat /etc/issue
    fi
); }

fn_vim_install() { (
    if command -v vim > /dev/null; then
        my_vim="$(command -v vim)"
        echo "[Info] Found ${my_vim}"
        return 0
    fi
    fn_apt_get vim vim
); }

fn_zip_install() { (
    if command -v zip > /dev/null; then
        my_zip="$(command -v zip)"
        echo "[Info] Found ${my_zip}"
        return 0
    fi
    fn_apt_get zip zip
); }

fn_fish_install() { (
    if ! command -v fish > /dev/null; then
        if [ "Darwin" = "$(uname -s)" ]; then
            printf "\e[31m[Warning]\e[0m \e[32mfish\e[0m not found\n"

            printf "\e[32m[Fixup]\e[0m install \e[34mfish\e[0m\n"
            sleep 1

            "${webi_cmd}" fish > /dev/null
        else
            fn_apt_get fish fish
        fi
    fi

    if ! test -f ~/.config/fish/config.fish; then
        printf "\e[32m[Fixup]\e[0m create \e[34m%s\e[0m\n" '~'/.config/fish/config.fish
        mkdir -p ~/.config/fish/
        touch ~/.config/fish/config.fish
        chmod 0600 ~/.config/fish/config.fish
    fi
); }

fn_touch() { (
    my_file_path="${1:-}"
    my_file_name="${2:-}"

    if test -f "${my_file_path}"; then
        echo "[Info] Found ${my_file_name}"
        return 0
    fi

    printf "\e[32m[Fixup]\e[0m create \e[34m%s\e[0m\n" "${my_file_name}"
    my_base_path="$(
        basename "${my_file_path}"
    )"

    if test ! -e "${my_base_path}"; then
        mkdir -p "${my_base_path}"
        chmod 0700 "${my_base_path}"
    fi

    touch "${my_file_path}"
    chmod 0600 "${my_file_path}"
); }

fn_mkdir() { (
    my_dir_name="${1:-}"
    my_dir_path="${2:-}"
    if test -d "${my_dir_path}"; then
        echo "[Info] Found ${my_dir_name}"
        return 0
    fi

    printf "\e[32m[Fixup]\e[0m create \e[34m%s\e[0m\n" "${my_dir_name}"
    mkdir -p "${my_dir_path}"
    chmod 0700 "${my_dir_path}"
); }

fn_path_bin() { (
    if test -d ~/bin/; then
        echo "[Info] Found ~/bin/"
        return 0
    fi

    printf "\e[32m[Fixup]\e[0m create \e[34m%s\e[0m\n" '~'/bin/
    mkdir -p ~/bin/
    "${pathman_cmd}" add ~/bin/ > /dev/null 2> /dev/null
); }

fn_webi_bin() { (
    my_cmd="$(
        echo "${1:-}" | sed 's/@.*//'
    )"

    if test -e ~/.local/bin/"${my_cmd}"; then
        echo "[Info] Found ~/.local/bin/${my_cmd}"
        return 0
    fi

    printf "\e[32m[Fixup]\e[0m Installing \e[32m%s\e[0m to \e[34m%s\e[0m\n" "${my_cmd}" '~'"/.local/bin/${my_cmd}"

    "${webi_cmd}" "${my_cmd}" > /dev/null 2> /dev/null
); }

fn_webi_opt() { (
    my_cmd="${1:-}"

    # shellcheck disable=SC2010
    # we do want to use ls with grep
    if ls ~/.local/opt/ | grep -q -E "^${my_cmd}(-|\$)"; then
        return 0
    fi

    printf "\e[32m[Fixup]\e[0m Installing \e[32m%s\e[0m to \e[34m%s/\e[0m\n" "${my_cmd}" '~'"/.local/opt/${my_cmd}"

    "${webi_cmd}" "${my_cmd}" > /dev/null
); }

fn_webi_vim_config() { (
    my_cmd="${1:-}"

    if test -e ~/.vim/plugins/"${my_cmd}.vim"; then
        echo "[Info] Found ~/.vim/plugins/${my_cmd}.vim"
        return 0
    fi

    printf "\e[32m[Fixup]\e[0m Installing \e[32m%s\e[0m to \e[34m%s.vim\e[0m\n" "vim-${my_cmd}" '~'"/.vim/plugins/${my_cmd}.vim"

    "${webi_cmd}" "vim-${my_cmd}" > /dev/null
); }

fn_webi_vim_plugin_ale() { (
    my_cmd="ale"

    if test -e ~/.vim/pack/plugins/start/"${my_cmd}"; then
        echo "[Info] Found ~/.vim/pack/plugins/start/${my_cmd}"
        return 0
    fi

    printf "\e[32m[Fixup]\e[0m Installing \e[32m%s\e[0m to \e[34m%s\e[0m\n" "vim-${my_cmd}" '~'"/.vim/pack/plugins/start/${my_cmd}"
    printf "\e[32m[Fixup]\e[0m     and config at \e[34m%s.vim\e[0m\n" '~'"/.vim/plugins/${my_cmd}"

    "${webi_cmd}" "vim-${my_cmd}" > /dev/null 2> /dev/null
); }

fn_webi_vim_plugin() { (
    my_cmd="${1:-}"

    if test -e ~/.vim/pack/plugins/start/"vim-${my_cmd}"; then
        echo "[Info] Found ~/.vim/pack/plugins/start/vim-${my_cmd}"
        return 0
    fi

    printf "\e[32m[Fixup]\e[0m Installing \e[32m%s\e[0m to \e[34m%s\e[0m\n" "vim-${my_cmd}" '~'"/.vim/pack/plugins/start/vim-${my_cmd}"
    printf "\e[32m[Fixup]\e[0m     and config at \e[34m%s.vim\e[0m\n" '~'"/.vim/plugins/${my_cmd}"

    "${webi_cmd}" "vim-${my_cmd}" > /dev/null 2> /dev/null
); }

fn_webi_vimrc() { (
    my_cmd="${1:-}"

    if grep -q "${my_cmd}" ~/.vimrc; then
        echo "[Info] Found vim-${my_cmd} config in ~/.vimrc"
        return 0
    fi

    printf "\e[32m[Fixup]\e[0m Installing \e[32m%s\e[0m to \e[34m%s\e[0m\n" "vim-${my_cmd}" '~'/.vimrc

    "${webi_cmd}" "vim-${my_cmd}" > /dev/null
); }

fn_setalias() { (
    my_name="${1:-}"
    my_cmd="${2:-}"

    if grep -q "${my_name}" ~/.config/envman/alias.env; then
        echo "[Info] Found '${my_name}' alias"
        return 0
    fi

    printf "\e[32m%s\e[0m aliased to '\e[34m%s\e[0m'\n" "${my_name}" "${my_cmd}"

    "${aliasman_cmd}" "${my_name}" "${my_cmd}" > /dev/null
); }

__install() {
    #printf "\e[31mRED\e[0m\n"
    #printf "\e[32mYELLOW\e[0m\n"
    #printf "\e[34mBLUE\e[0m\n"

    echo ""
    printf "\e[34mLog\e[0m will be written to \e[32m%s\e[0m\n" '~'/.local/share/beyond-code/var/
    sleep 2

    echo ""
    mkdir -p ~/.local/share/beyond-code/var/
    mkdir -p ~/.local/opt/
    {
        printf "\e[32mwebi\e[0m at \e[32m%s\e[0m\n" '~'/.local/bin/webi
        echo ""

        if [ "Darwin" = "$(uname -s)" ]; then
            if test -e /Applications/iTerm.app; then
                echo "[Info] Found iTerm.app in /Applications/"
            else
                printf "\e[32m[Fixup]\e[0m Installing \e[32m%s\e[0m into \e[34m%s\e[0m\n" "iTerm.app" "/Applications/"
                "${webi_cmd}" iterm2 > /dev/null
            fi
        fi

        fn_git_install
        fn_fish_install
        fn_zip_install

        if test -e ~/.local/share/fonts/'Droid Sans Mono for Powerline Nerd Font Complete.otf'; then
            echo "[Info] Found NerdFont in ~/.local/share/fonts"
        elif test -e ~/Library/Fonts/'Droid Sans Mono for Powerline Nerd Font Complete.otf'; then
            echo "[Info] Found NerdFont in ~/Library/Fonts"
        else
            "${webi_cmd}" nerdfont | tail -n 1
        fi

        if test -e ~/.iterm2/; then
            echo "[Info] Found iTerm2 utils ~/.iterm2/"
        else
            printf "\e[32m[Fixup]\e[0m Installing \e[32m%s\e[0m into \e[34m%s\e[0m\n" "iterm2-utils" '~'"/.iterm2/"
            "${webi_cmd}" iterm2-utils > /dev/null
        fi

        echo ""
        echo "[Info] PATH updates in ~/.config/envman/PATH.env"
        fn_path_bin
        fn_touch ~/.config/envman/alias.env '~'/.config/envman/alias.env
        fn_touch ~/.config/envman/PATH.env '~'/.config/envman/PATH.env

        echo ""
        fn_node_install
        for my_cmd in aliasman bat curlie jq pathman ssh-pubkey; do
            fn_webi_bin "${my_cmd}"
        done

        echo ""
        echo "[Info] Aliases in ~/.config/envman/alias.env"
        fn_setalias setalias 'aliasman'
        fn_setalias cat 'bat --style=plain --pager=none'
        fn_setalias curl 'curlie'

        # vim config and plugins
        echo ""
        fn_vim_install
        fn_touch ~/.vimrc '~'/.vimrc
        for my_plugin in leader shell; do
            fn_webi_vimrc "${my_plugin}"
        done
        fn_webi_vim_plugin sensible
        for my_plugin in viminfo smartcase spell whitespace; do
            fn_webi_vim_config "${my_plugin}"
        done
        fn_webi_vim_plugin_ale
        for my_plugin in commentary lastplace shfmt prettier; do
            fn_webi_vim_plugin "${my_plugin}"
        done
        for my_cmd in shfmt@3.5 shellcheck; do
            fn_webi_bin "${my_cmd}"
        done

    } | tee -a "${my_log}"

    echo ""
    printf "\e[34mLog\e[0m written to \e[32m%s\e[0m\n" "${my_log}"
    echo ""
}

__install
