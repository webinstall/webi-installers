#!/bin/bash
set -e
set -u

__redirect_alias_rustlang() {
    echo "'rust' is an alias for 'rustlang'"
    WEBI_HOST=${WEBI_HOST:-"https://webinstall.dev"}
    curl -fsSL "$WEBI_HOST/rustlang@${WEBI_VERSION:-}" | bash
}

__redirect_alias_rustlang
