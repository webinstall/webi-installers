#!/bin/sh

set -e
set -u

__redirect_alias_python() {
    echo "'python@${WEBI_TAG:-stable}' is an alias for 'python@${WEBI_VERSION-}'"
    WEBI_HOST=${WEBI_HOST:-"https://webinstall.dev"}
    curl -fsSL "$WEBI_HOST/python@${WEBI_VERSION-}" | sh
}

__redirect_alias_python
