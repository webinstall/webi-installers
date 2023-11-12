#!/bin/sh
set -e
set -u

__redirect_alias_pwsh() {
    echo "'powershell@${WEBI_TAG:-stable}' is an alias for 'pwsh@${WEBI_VERSION-}'"
    WEBI_HOST=${WEBI_HOST:-"https://webinstall.dev"}
    curl -fsSL "$WEBI_HOST/pwsh@${WEBI_VERSION-}" | sh
}

__redirect_alias_pwsh
