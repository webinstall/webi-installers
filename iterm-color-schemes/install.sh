#!/bin/bash
set -e
set -u

function __redirect_alias_iterm2_themes() {
    echo "'iterm-color-schemes@${WEBI_TAG:-stable}' is an alias for 'iterm2-themes@${WEBI_VERSION:-}'"
    WEBI_HOST=${WEBI_HOST:-"https://webinstall.dev"}
    curl -fsSL "$WEBI_HOST/iterm2-themes@${WEBI_VERSION:-}" | bash
}

__redirect_alias_iterm2_themes
