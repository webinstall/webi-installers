#!/bin/sh
set -e
set -u

__redirect_alias_psql() {
    echo "'postgresql-client' is an alias for 'psql'"
    sleep 2.5
    WEBI_HOST=${WEBI_HOST:-"https://webi.sh"}
    curl -fsSL "$WEBI_HOST/psql@${WEBI_VERSION-}" | sh
}

__redirect_alias_psql
