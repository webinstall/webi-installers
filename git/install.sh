#!/bin/bash
set -e
set -u

function __init_git() {

    if [ -z "$(command -v git)" ]; then
        if [[ -n "$(uname -a | grep -i darwin)" ]]; then
            >&2 echo "Error: 'git' not found. You may have to re-install 'git' on Mac after every major update."
            >&2 echo "       for example, try: xcode-select --install"
            # sudo xcodebuild -license accept
        else
            >&2 echo "Error: to install 'git' on Linux use the built-in package manager."
            >&2 echo "       for example, try: xcode-select --install"
        fi
        exit 1
    else
        echo "'git' already installed"
    fi

}

__init_git()
