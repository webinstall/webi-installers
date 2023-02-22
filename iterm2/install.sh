#!/bin/sh

set -e
set -u

_install_iterm2() {
    # only for macOS
    if [ "Darwin" != "$(uname -s)" ]; then
        echo ""
        echo "iTerm2 is only for macOS"
        echo ""
        echo "You might want to check out:"
        echo "    alacritty for Linux"
        echo "    Windows Terminal for Windows, of course"
        echo ""
        exit 1
    fi

    webi_download
    webi_extract

    if [ ! -d "${WEBI_TMP}/iTerm.app" ]; then
        echo "error unpacking iTerm2:"
        ls -lAF "${WEBI_TMP}"
        exit 1
    fi

    if [ -d /Applications/iTerm.app ]; then
        mv /Applications/iTerm.app "${WEBI_TMP}/iTerm.app-webi.bak"
    fi
    mkdir -p /Applications/
    mv "${WEBI_TMP}/iTerm.app" /Applications/
}

_install_iterm2
