#!/bin/sh

__init_nerdfont() {
    set -e
    set -u

    my_nerdfont="Droid Sans Mono for Powerline Nerd Font Complete.otf"
    curl -fsSLo "$my_nerdfont" \
        'https://github.com/ryanoasis/nerd-fonts/raw/v2.3.3/patched-fonts/DroidSansMono/complete/Droid%20Sans%20Mono%20Nerd%20Font%20Complete.otf'

    my_fontdir=""
    if [ -e "$HOME/Library/Fonts" ]; then
        # OS X
        mv "$my_nerdfont" ~/Library/Fonts/
        my_fontdir="Library/Fonts/"
    else
        # Linux
        mkdir -p ~/.local/share/fonts
        mv "$my_nerdfont" ~/.local/share/fonts/
        my_fontdir=".local/share/fonts/"
    fi

    echo "Installed $my_nerdfont to ~/$my_fontdir"
}

__init_nerdfont
