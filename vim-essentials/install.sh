#!/bin/sh
set -e
set -u

__init_vim_essentials() {
    "$HOME/.local/bin/webi" \
        vim-leader \
        vim-shell \
        vim-sensible \
        vim-viminfo \
        vim-lastplace \
        vim-smartcase \
        vim-spell \
        vim-ale \
        vim-whitespace \
        vim-shfmt \
        vim-prettier \
        shellcheck \
        shfmt \
        prettier
    # done

    printf '\n'
    printf 'Suggestion: Also check out these great plugins:\n'
    printf '\n'
    # shellcheck disable=SC2016
    printf '    - vim-commentary (`gc` to toggle comment blocks)\n'
    # shellcheck disable=SC2016
    printf '    - vim-nerdtree (`space + n` for dir tree, `o` to open file)\n'
    printf '    - vim-gui      (mouse & clipboard support)\n'
    printf '    - vim-devicons (use nerdfont icons in vim)\n'
    printf '\n'
    printf '    - jshint       (JavaScript linting, works with vim-ale)\n'
    printf '    - vim-go       (golang linting, etc)\n'
    printf '    - vim-rust     (rustlang linting, etc)\n'
    printf '\n'
}

__init_vim_essentials
