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

    if test -d /Applications/iTerm.app; then
        my_curver="$(
            grep -A 2 CFBundleShortVersionString \
                /Applications/iTerm.app/Contents/Info.plist |
                tr '<> \t' '\n' |
                grep -E '\d\.\d\.\d'
        )"
        if test "${my_curver}" = "${WEBI_VERSION}"; then
            echo "    Found /Applications/iTerm.app/ (${my_curver})"
            return 0
        fi

        echo "    Replacing /Applications/iTerm.app/ (${my_curver})"
        mv /Applications/iTerm.app "${WEBI_TMP}/iTerm.app-webi.bak"
    fi

    webi_download \
        "${WEBI_PKG_URL}" \
        "${WEBI_PKG_PATH}/${WEBI_PKG_FILE}"

    webi_extract

    if [ ! -d "${WEBI_TMP}/iTerm.app" ]; then
        echo "error unpacking iTerm2:"
        ls -lAF "${WEBI_TMP}"
        exit 1
    fi

    mkdir -p /Applications/
    mv "${WEBI_TMP}/iTerm.app" /Applications/
    echo "    Installed to /Applications/iTerm.app/"
}

_install_iterm2
