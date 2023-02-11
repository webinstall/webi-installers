#!/bin/sh
set -e
set -u

__init_git() {

    if [ -z "$(command -v git)" ]; then
        if [ "Darwin" = "$(uname -s)" ]; then
            echo >&2 "Error: 'git' not found. You may have to re-install 'git' on Mac after every major update."
            echo >&2 "       for example, try: xcode-select --install"
            # sudo xcodebuild -license accept
        else
            echo >&2 "Error: to install 'git' on Linux use the built-in package manager."
            echo >&2 "       for example, try: sudo apt install -y git"
        fi
        exit 1
    else
        echo "'git' already installed"
    fi

}

__init_git
