#!/bin/sh
set -e
set -u

__init_git() {

    if command -v git > /dev/null; then
        echo "'git' already installed"
        return 0
    fi

    if [ "Darwin" = "$(uname -s)" ]; then
        echo >&2 "Error: 'git' not found. You may have to re-install 'git' on Mac after every major update."
        echo >&2 "       for example, try: xcode-select --install"
        # sudo xcodebuild -license accept
    else
        fn_prompt_sudo_install git
    fi

    exit 1
}

fn_prompt_sudo_install() {
    a_pkg="${1}"

    if command -v sudo > /dev/null; then
        my_answer='n'
        cmd_pkg_add=''
        if command -v apt > /dev/null; then
            echo ""
            echo "ERROR"
            echo "    No Webi installer for ${a_pkg} on Linux yet."
            echo ""
            echo "SOLUTION"
            echo "    Would you like to install with apt?"
            echo "    sudo apt install -y ${a_pkg}"
            echo ""
            printf "Install with sudo and apt [Y/n]? "
            cmd_pkg_add='sudo apt install -y'
        elif command -v apk > /dev/null; then
            echo ""
            echo "ERROR"
            echo "    No Webi installer for ${a_pkg} on Alpine yet."
            echo ""
            echo "SOLUTION"
            echo "    Would you like to install with apk?"
            echo "    sudo apk add --no-cache ${a_pkg}"
            echo ""
            printf "Install with sudo and apk [Y/n]? "
            cmd_pkg_add='sudo apk add --no-cache'
        elif test "Darwin" != "$(uname -s)"; then
            echo "No ${a_pkg} installer for Linux yet."
            exit 1
        fi

        read -r my_answer < /dev/tty
        if test -z "${my_answer}" ||
            test "${my_answer}" = "Y" ||
            test "${my_answer}" = "y"; then
            $cmd_pkg_add "${a_pkg}"
        else
            exit 1
        fi
    elif test "Darwin" != "$(uname -s)"; then
        echo "No ${a_pkg} installer for Linux yet."
        exit 1
    fi
}

__init_git
