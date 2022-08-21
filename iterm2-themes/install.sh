#!/bin/sh
set -u
set -e

__install_iterm2_color_schemes() {
    WEBI_HOST=${WEBI_HOST:-https://webinstall.dev}

    echo ''
    mkdir -p ~/Downloads/webi/iterm2-themes/

    echo 'Downloading themes ...'
    echo ''
    curl -sSL "${WEBI_HOST}"'/packages/iterm2/schemes/Tomorrow%20Night.itermcolors' \
        -o ~/Downloads/webi/iterm2-themes/'Tomorrow Night.itermcolors'
    echo '    Tomorrow Night'

    curl -sSL "${WEBI_HOST}"'/packages/iterm2/schemes/Firewatch.itermcolors' \
        -o ~/Downloads/webi/iterm2-themes/'Firewatch.itermcolors'
    echo '    Firewatch'

    curl -sSL "${WEBI_HOST}"'/packages/iterm2/schemes/Dracula.itermcolors' \
        -o ~/Downloads/webi/iterm2-themes/'Dracula.itermcolors'
    echo '    Dracula'

    curl -sSL "${WEBI_HOST}"'/packages/iterm2/schemes/Elemental.itermcolors' \
        -o ~/Downloads/webi/iterm2-themes/'Elemental.itermcolors'
    echo '    Elemental'

    curl -sSL "${WEBI_HOST}"'/packages/iterm2/schemes/Ubuntu.itermcolors' \
        -o ~/Downloads/webi/iterm2-themes/'Ubuntu.itermcolors'
    echo '    Ubuntu'

    curl -sSL "${WEBI_HOST}"'/packages/iterm2/schemes/cyberpunk.itermcolors' \
        -o ~/Downloads/webi/iterm2-themes/'cyberpunk.itermcolors'
    echo '    cyberpunk'

    curl -sSL "${WEBI_HOST}"'/packages/iterm2/schemes/Hivacruz.itermcolors' \
        -o ~/Downloads/webi/iterm2-themes/'Hivacruz.itermcolors'
    echo '    Hivacruz'

    curl -sSL "${WEBI_HOST}"'/packages/iterm2/schemes/ToyChest.itermcolors' \
        -o ~/Downloads/webi/iterm2-themes/'ToyChest.itermcolors'
    echo '    ToyChest'

    echo ''
    echo 'IMPORTANT: You must open the themes to install them:'
    echo ''
    echo '    open ~/Downloads/webi/iterm2-themes/*.itermcolors'
    echo ''
}

__install_iterm2_color_schemes
