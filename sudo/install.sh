#!/bin/sh
set -e
set -u

__init_sudo() {

    if command -v sudo > /dev/null; then
        echo "'sudo' already installed"
        exit 0
    fi

    echo >&2 "Error: on Linux & BSD use the native package manager to install sudo:"
    echo >&2 "    For Ubuntu / Debian:"
    echo >&2 "       apt install -y sudo"
    echo >&2 ""
    echo >&2 "    For Alpine / Docker:"
    echo >&2 "       apk add sudo"
    echo >&2 ""

    exit 1
}

__init_sudo
