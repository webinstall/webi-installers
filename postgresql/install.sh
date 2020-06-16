# title: PostgreSQL (Postgres alias)
# homepage: https://webinstall.dev/postgres
# tagline: Alias for https://webinstall.dev/postgres
# alias: postgres
# description: |
#   See https://webinstall.dev/postgres

echo "'postgresql' is an alias for 'postgres'"
curl -fsSL https://webinstall.dev/postgres@${WEBI_VERSION:-} | bash
