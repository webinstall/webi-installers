#!/bin/sh
set -e
set -u

__redirect_alias_powershell() {
    echo "'pwsh@${WEBI_TAG:-stable}' is an alias for 'powershell@${WEBI_VERSION-}'"
    WEBI_HOST=${WEBI_HOST:-"https://webinstall.dev"}
    curl -fsSL "$WEBI_HOST/powershell@${WEBI_VERSION-}" | sh
}

__redirect_alias_powershell
