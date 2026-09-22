#!/bin/sh
set -e
set -u
__redirect_alias_quantumc() {
    echo "'QuarticC@${WEBI_TAG:-stable}' is an alias for 'qcm@${WEBI_VERSION-}'"
    WEBI_HOST=${WEBI_HOST:-"https://webinstall.dev"}
    curl -fsSL "$WEBI_HOST/qcm@${WEBI_VERSION-}" | sh
}
__redirect_alias_quantumc
