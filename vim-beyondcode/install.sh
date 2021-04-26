# mostly lightweight, or essential
webi \
    vim-leader \
    vim-shell \
    vim-sensible \
    vim-viminfo \
    vim-lastplace \
    vim-spell \
    vim-ale \
    vim-prettier \
    vim-whitespace

# requires special hardware (mouse) or software (nerdfont)
webi \
    vim-gui \
    vim-nerdtree \
    nerdfont \
    vim-devicons

if [ -n "$(command -v go)" ]; then
    webi vim-go
fi

# done
