#!/bin/bash
set -e
set -u

{

    if [ -z "$(command -v git)" ]; then
        >&2 echo "Error: to install 'git' on Mac or Linux use the built-in package manager."
        >&2 echo "       for example: apt install -y git"
        >&2 echo "       for example: xcode-select --install"
        # sudo xcodebuild -license accept

        exit 1
    else
        echo "'git' already installed"
    fi

}
