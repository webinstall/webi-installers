#!/bin/bash
# title: PostgreSQL (Postgres alias)
# homepage: https://webinstall.dev/postgres
# tagline: Alias for https://webinstall.dev/postgres
# alias: postgres
# description: |
#   See https://webinstall.dev/postgres

function __redirect_alias_postgres() {
    echo "'postgresql' is an alias for 'postgres'"
    WEBI_HOST=${WEBI_HOST:-"https://webinstall.dev"}
    curl -fsSL "$WEBI_HOST/postgres@${WEBI_VERSION:-}" | bash
}

__redirect_alias_postgres
