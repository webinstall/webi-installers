#!/bin/sh
set -e
set -u

__redirect_alias_mariadb() {
    echo "'mariadb-server' is an alias for 'mariadb'"
    sleep 2.5
    WEBI_HOST=${WEBI_HOST:-"https://webi.sh"}
    curl -fsSL "$WEBI_HOST/mariadb@${WEBI_VERSION-}" | sh
}

__redirect_alias_mariadb
