#!/bin/bash
# title: GnuPG (gpg alias)
# homepage: https://webinstall.dev/gpg
# tagline: Alias for https://webinstall.dev/gpg
# alias: gpg
# description: |
#   See https://webinstall.dev/gpg

function __redirect_alias_gpg() {
    echo "'gnupg@${WEBI_TAG:-stable}' is an alias for 'gpg@${WEBI_VERSION:-}'"
    WEBI_HOST=${WEBI_HOST:-"https://webinstall.dev"}
    curl -fsSL "$WEBI_HOST/gpg@${WEBI_VERSION:-}" | bash
}

__redirect_alias_gpg
