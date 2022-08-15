#!/bin/bash
set -e
set -u

__init_vim_essentials() {
    "$HOME/.local/bin/webi" \
        vim-leader \
        vim-shell \
        vim-sensible \
        vim-viminfo \
        vim-lastplace \
        vim-spell \
        vim-ale \
        shellcheck \
        shfmt \
        vim-shfmt \
        prettier \
        vim-prettier \
        vim-whitespace
    # done

    printf '\n'
    printf 'Suggestion: Also check out these great plugins:\n'
    printf '\n'
    printf '    - vim-nerdtree (better than the default file browser)\n'
    printf '    - vim-gui      (mouse & clipboard support)\n'
    printf '    - vim-devicons (use nerdfont icons in vim)\n'
    printf '\n'
    printf '    - jshint       (JavaScript linting, works with vim-ale)\n'
    printf '    - vim-go       (golang linting, etc)\n'
    printf '    - vim-rust     (rustlang linting, etc)\n'
    printf '\n'
}

__init_vim_essentials
