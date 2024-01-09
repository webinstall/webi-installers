#!/bin/sh
set -e
set -u

fn_install_xcode_commandlinetools() { (
    b_os="$(uname -s)"
    if test "${b_os}" != 'Darwin'; then
        echo >&2 'XCode Command Line Tools are for macOS only'
        return 1
    fi

    # streamline the output to be pretty
    fn_check_pkg '/Library/Developer/CommandLineTools/usr/bin/clang' 'clang'
    fn_check_pkg '/Library/Developer/CommandLineTools/usr/bin/git' 'git'
    fn_check_pkg '/Library/Developer/CommandLineTools/usr/bin/make' 'make'
    echo >&2 ""

    # git
    if xcode-select -p > /dev/null 2> /dev/null; then
        echo ""
        return 0
    fi

    cmd_xcode_cli_tools_install="xcode-select --install"
    echo "    Running $(t_cmd "${cmd_xcode_cli_tools_install}")"
    $cmd_xcode_cli_tools_install 2> /dev/null
    echo ""
    echo ">>> $(t_attn 'ACTION REQUIRED') <<<"
    echo ""
    echo "        $(t_attn "Click") '$(t_bold 'Install')' $(t_attn "in the pop-up")"
    echo "        (it may appear $(t_em 'under') this window)"
    echo ""
    echo "^^^ $(t_attn 'ACTION REQUIRED') ^^^"
    echo ""
    printf "    waiting %s to finish installing Command Line Developer Tools ..." "$(t_em 'for you')"
    while ! test -x /Library/Developer/CommandLineTools/usr/bin/git ||
        ! test -x /Library/Developer/CommandLineTools/usr/bin/make; do
        sleep 0.25
    done
    echo " $(t_info 'OK')"
    echo "    Installed to $(t_path '/Library/Developer/CommandLineTools/')"
    sleep 1
); }

fn_check_pkg() { (
    a_pkg="${1}"
    a_pkgname="${2:-$a_pkg}"

    printf >&2 '    %s %s %s' \
        "$(t_dim "Checking for")" \
        "$(t_pkg "${a_pkgname}")" \
        "$(t_dim "...")"

    if command -v "${a_pkg}" > /dev/null; then
        echo >&2 " $(t_dim 'OK')"
        return 0
    fi

    echo >&2 ' missing'
); }

fn_install_xcode_commandlinetools
