#!/bin/sh
set -e
set -u

__redirect_alias_trip() {
    echo "'trippy@${WEBI_TAG:-stable}' is an alias for 'trip@${WEBI_VERSION-}'"
    WEBI_HOST=${WEBI_HOST:-"https://webinstall.dev"}
    curl -fsSL "$WEBI_HOST/trip@${WEBI_VERSION-}" | sh
}

__redirect_alias_trip
