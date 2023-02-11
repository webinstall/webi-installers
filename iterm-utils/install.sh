#!/bin/sh
set -e
set -u

__redirect_alias_iterm2_utils() {
    echo "'iterm-utils@${WEBI_TAG:-stable}' is an alias for 'iterm2-utils@${WEBI_VERSION-}'"
    WEBI_HOST=${WEBI_HOST:-"https://webinstall.dev"}
    curl -fsSL "$WEBI_HOST/iterm2-utils@${WEBI_VERSION-}" | sh
}

__redirect_alias_iterm2_utils
