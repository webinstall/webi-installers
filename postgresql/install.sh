#!/bin/sh
set -e
set -u

__redirect_alias_postgres() {
    echo "'postgresql' is an alias for 'postgres'"
    WEBI_HOST=${WEBI_HOST:-"https://webinstall.dev"}
    curl -fsSL "$WEBI_HOST/postgres@${WEBI_VERSION-}" | sh
}

__redirect_alias_postgres
