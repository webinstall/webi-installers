#!/bin/sh
set -e
set -u

__redirect_alias_vim_zig() {
    echo "'zig.vim@${WEBI_TAG:-}' is an alias for 'vim-zig@${WEBI_VERSION:-}'"
    WEBI_HOST=${WEBI_HOST:-"https://webinstall.dev"}
    curl -fsSL "$WEBI_HOST/vim-zig@${WEBI_VERSION:-}" | sh
}

__redirect_alias_vim_zig
