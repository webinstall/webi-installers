#!/bin/sh
set -e
set -u

__redirect_alias_iterm2_themes() {
    echo "'iterm2-color-schemes@${WEBI_TAG:-stable}' is an alias for 'iterm2-themes@${WEBI_VERSION-}'"
    WEBI_HOST=${WEBI_HOST:-"https://webinstall.dev"}
    curl -fsSL "$WEBI_HOST/iterm2-themes@${WEBI_VERSION-}" | sh
}

__redirect_alias_iterm2_themes
