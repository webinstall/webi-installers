#!/bin/sh
set -e
set -u

__redirect_alias_gpg() {
    echo "'gnupg@${WEBI_TAG:-stable}' is an alias for 'gpg@${WEBI_VERSION-}'"
    WEBI_HOST=${WEBI_HOST:-"https://webinstall.dev"}
    curl -fsSL "$WEBI_HOST/gpg@${WEBI_VERSION-}" | sh
}

__redirect_alias_gpg
