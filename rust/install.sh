#!/bin/bash
# title: Rust (rustlang alias)
# homepage: https://webinstall.dev/rustlang
# tagline: Alias for https://webinstall.dev/rustlang
# alias: rustlang
# description: |
#   See https://webinstall.dev/rustlang

function __redirect_alias_rustlang() {
    echo "'rust' is an alias for 'rustlang'"
    WEBI_HOST=${WEBI_HOST:-"https://webinstall.dev"}
    curl -fsSL "$WEBI_HOST/rustlang@${WEBI_VERSION:-}" | bash
}

__redirect_alias_rustlang
