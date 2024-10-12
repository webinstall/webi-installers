#!/bin/sh
set -e
set -u

__redirect_alias_postgres() {
    echo "'postgresql' is an alias for 'postgres'"
    sleep 2.5
    WEBI_HOST=${WEBI_HOST:-"https://webi.sh"}
    curl -fsSL "$WEBI_HOST/postgres@${WEBI_VERSION-}" | sh
}

__redirect_alias_postgres
