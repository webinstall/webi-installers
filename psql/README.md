---
title: PSQL (PostgreSQL Client)
homepage: https://www.postgresql.org/
tagline: |
  psql: REPL for Postgres that supports standard TLS (+SNI,ALPN), .pgpass, and .psqlrc
---

To update or switch versions, run `webi psql@stable` (or `@v17.0`, `@beta`,
etc).

### Files

These are the files / directories that are created and/or modified with this
install:

```text
~/.config/envman/PATH.env
~/.local/opt/psql/
~/.pgpass
~/.psqlrc
~/.config/psql/psqlrc.sql
```

## Cheat Sheet

> `psql` serves as a model for what a great PostgreSQL Client should be:
>
> - gives you a nice REPL to run queries
> - manages authentication
> - allows table or list view
> - preloads user-specific settings

For localhost / private networking:

```sh
psql "postgres://postgres:postgres@localhost:5432/postgres"
psql "postgres://db-xxxx:secret123@pg-1.example.com:5432/db-xxxx"
```

For remote / public networks: \
(with `sslmode` & `sslnegotiation`)

```sh
psql "postgres://db-xxxx@pg-1.example.com:5432/db-xxxx?sslmode=require&sslnegotiation=direct"
```

## Table of Contents

- Server vs Client & PG Essentials
- Vertical Rows
- .pgpass
- .psqlrc
- How to Import / Export CSV
- How to Backup & Restore
- Session Variables (& Encryption Keys)

### Where to Find the Postgres Server Cheat Sheet

This is exclusively a client-side cheat sheet.

For the server-side / administrative cheat sheet, see
[The Postgres (Server) Cheat Sheet](../postgres/).

For a collection of other helpful scripts, see
[PG Essentials](https://github.com/bnnanet/pg-essentials):

- psql-example-connect
- psql-backup
- psql-store-credential

### How to View Rows Vertically

- use `\gx` instead of `;` for a single query
- use `\x` to toggle for all queries

```sql
SELECT id, character_name, description
FROM character_descriptions \gx
```

```text
-[ RECORD 1 ]--+------------------------------------------------------------------------------------------------------------------
id             | e17709d3-6e5a-4baa-91cc-8d5267815d5e
character_name | Harry Potter
description    | A teenager with a chronic case of "Chosen One" syndrome, who manages to stay alive by sheer luck.
-[ RECORD 2 ]--+------------------------------------------------------------------------------------------------------------------
id             | 68646acf-9468-4006-83a7-8ee748df4ca5
character_name | Spider-Man
description    | The neighborhood's most responsible guy, who balances high school stress with the casual task of saving the city.
```

- similar to `\G` in MySQL.

### How to use `~/.pgpass` for Passwords

Postgres passwords are stored in `~/.pgpass`.

You can use [psql-store-credential](https://github.com/bnnanet/pg-essentials) to
manage `~/.pgpass`, or manage it manually:

```sh
touch ~/.pgpass
chmod 0600 ~/.pgpass
```

```sh
# export PGPASSFILE='/Users/aj/.pgpass'
# hostname:port:database:username:password
localhost:5432:postgres:postgres:postgres
pg-1.example.com:5432:db-xxxx:secret123
localhost:*:*:postgres:postgres
*:*:db-xxxx:db-xxxx:secret123
*:*:*:postgres
```

- this _ONLY_ supplies a password - not a default username or db name
- the _Database Name_ and _User Name_ are typically the same \
  (as per `samename` in `hba.conf`)
- all but the password can `*` wildcards
- the first line to match (_NOT_ the most specific) will used for password

### How to setup `~/.psqlrc` for Per-DB history

Allows you to keep per-database history and settings, such as encryption keys.

```sh
mkdir -p ~/.config/psql/

touch ~/.psqlrc
touch ~/.config/psql/psqlrc.sql

chmod 0600 ~/.psqlrc
chmod 0700 ~/.config ~/.config/psql/
chmod 0600 ~/.config/psql/psqlrc.sql
```

`~/.psqlrc`

```sql
\i ~/.config/psql/psqlrc.sql
```

`~/.config/psql/psqlrc.sql`:

```sql
-- psql meta-commands: https://www.postgresql.org/docs/current/app-psql.html

--
-- Per-DB Configuration
--
\set HISTFILE ~/.config/psql/ :DBNAME /history
\set confdir ~/.config/psql/ :DBNAME
\set dbrc :confdir /psqlrc.sql
\if `mkdir -p :confdir && chmod 0700 :confdir && echo n || echo y`
    \echo [WARN] could not create :confdir
    \set HISTFILE ~/.config/psql/history
\else
    \if `test -f :dbrc || touch :dbrc && chmod 0600 :dbrc && echo n || echo y`
        \echo [WARN] could not create :dbrc
    \else
        \echo loading :dbrc
        \i :dbrc
    \endif
    \if `test -f :HISTFILE || touch :HISTFILE && chmod 0600 :HISTFILE && echo n || echo y`
        \echo [WARN] could not create :HISTFILE
        \set HISTFILE ~/.config/psql/history
    \endif
\endif
\unset :dbrc

--
-- Session Preferences
--
-- ignore space-prefixed commands and duplicates
\echo using :HISTFILE for command history

\set QUIET on
\set HISTCONTROL ignoreboth
\set ON_ERROR_ROLLBACK interactive
\set COMP_KEYWORD_CASE upper
\pset pager off
\pset null '(null)'

-- set to YOUR timezone
SET TIME ZONE 'America/Denver';

\unset QUIET

\echo ''
```

- `HISTCONTROL ignoreboth` causes lines starting with a space and duplicate
  lines to be omitted from history

### How to Work with CSVs

- `\copy` saves client-side (locally, relative to `psql`)
  - MUST be on a SINGLE LINE (no newlines)
  - (use a temporary view for for queries that don't easily fit on a line)
- `COPY` saves server-side (remote, relative to `postgres`)

#### How to Export to CSV

```sql
\copy "character_descriptions" TO './character_descriptions.csv' WITH CSV HEADER;
```

```sql
CREATE TEMP VIEW "character_descriptions_csv" AS
SELECT "character_name", "description"
FROM "character_descriptions";

\copy (SELECT * FROM "character_descriptions_csv") TO './character_descriptions.csv' WITH CSV HEADER;
```

#### How to Import from CSV

```sql
\copy "character_descriptions"("id", "character_name", "description") FROM './character_descriptions.csv' WITH (FORMAT csv, HEADER);
```

### How to Backup & Restore

To backup in a way that will be easy to restore:

- save the schema separately from the data
- don't include database-specific roles or permissions
- store the password in `~/.pgpass` as described above

You can use a helper script like
[psql-backup](https://github.com/bnnanet/pg-essentials), or create your own:

Given these credentials:

```sh
my_user="db_xxxx"
my_db="db_xxxx"
my_host="pg-1.example.com"
my_port="5432"
```

And these [`pg_dump`](https://www.postgresql.org/docs/current/app-pgdump.html)
commands:

```sh
pg_dump --no-privileges --no-owner --schema-only --clean \
    --username "$my_user" --no-password --host "$my_host" --port "$my_port" \
    -f ./"$my_db".schema.drop.sql "$my_db" >&2

pg_dump --no-privileges --no-owner --schema-only \
    --username "$my_user" --no-password --host "$my_host" --port "$my_port" \
    -f ./"$my_db".schema.sql "$my_db" >&2

pg_dump --no-privileges --no-owner --data-only \
    --username "$my_user" --no-password --host "$my_host" --port "$my_port" \
    -f ./"$my_db".data.sql "$my_db"
```

You'll get your data is this format:

```text
db_xxxx.schema.drop.sql # will replace (DELETE) all tables with empty tables
db_xxxx.schema.sql      # will create new empty tables
db_xxxx.data.sql        # will load data
```

To restore / copy to another database:

```sh
new_user="db_yyyy"
new_db="db_yyyy"
psql "postgres://$new_user@$my_host:$my_port/$new_db" < ./db_xxxx.schema.sql
psql "postgres://$new_user@$my_host:$my_port/$new_db" < ./db_xxxx.data.sql
```

Or use
[`pg_restore`](https://www.postgresql.org/docs/current/app-pgrestore.html).

See the examples at:

- https://github.com/bnnanet/pg-essentials?tab=readme-ov-file#psql-backup
- https://github.com/therootcompany/pg-xzbackup.sh

### How to use Session Variables

Given the example `psqlrc` above which creates per-db history and config files,
you can create a config file with the session variables you'd like to use in
queries:

`~/.config/psql/db_xxxx/psqlrc.sql`:

```
-- ex: add conventional "my" extension with client params for pgp and raw encryption
SET SESSION "my"."client_id" = '12345678';
-- note: MUST be cast to ::bytea explicitly
--       SELECT current_setting('my.aes_128_key')::bytea;
SET SESSION "my"."aes_128_key" = E'\\xdeadbeefbadc0ffee0ddf00dcafebabe';
SET SESSION "my"."pgp_password" = 'zoo zoo zoo zoo zoo zoo zoo zoo zoo zoo zoo right';
```

```sql
SELECT current_setting('my.aes_128_key')::bytea;
SELECT current_setting('my.pgp_password');
```

- Bound to the _CURRENT LOGIN SESSION_ only
- Can be used as a _VALUE_, anywhere - such as in _FUNCTIONS_ and _VIEWS_
- Must must be scoped "extension"."var", where "extension" is arbitrary \
  (conventionally "my", but can be anything that isn't already a schema)
- Can also be used programmatically by clients in an `exec()` or `query()`

#### Example Raw AES Encryption

This shows a full encrypt and decrypt example, using `current_setting()` to get
a key.

```sql
-- raw encrypt / decrypt example
WITH "aes_key_cte" AS (
    SELECT
        current_setting('my.aes_128_key')::bytea AS "aes_key",
        'sensitive data (raw)' AS "plain_original"
),
"raw_example_table_cte" AS (
    SELECT
        "aes_key",
        "plain_original",
        encrypt(convert_to("plain_original", 'UTF8'), "aes_key", 'aes') AS "raw_enc_column"
    FROM
        "aes_key_cte"
)
SELECT
    "plain_original",
    "raw_enc_column",
    convert_from(decrypt("raw_enc_column", "aes_key", 'aes'), 'UTF8') AS "plain_decrypted",
    convert_from(decrypt_iv(
        "raw_enc_column", "aes_key", E'\\x00000000000000000000000000000000', 'aes'),
    'UTF8') AS "plain_decrypted_iv"
FROM
    "raw_example_table_cte"
;
```

In practice, using a simple and efficient SQL functions can help abstract away
the tedious bits.

See:

- https://www.postgresql.org/docs/current/pgcrypto.html#PGCRYPTO-RAW-ENC-FUNCS

#### Example PGP AES Encryption

```sql
-- pgp_sym encrypt / decrypt example
WITH "pgp_pass_cte" AS (
    SELECT
        'sensitive data (pgp)' AS "plain_original",
        current_setting('my.pgp_password') AS "pgp_pass"
),
"pgp_example_table_cte" AS (
    SELECT
        -- pgp_sym_encrypt(data text, psw text [, options text ]) returns bytea
        -- pgp_sym_encrypt_bytea(data bytea, psw text [, options text ]) returns bytea
        pgp_sym_encrypt(
            'sensitive data (pgp)',
            "pgp_pass",
            'cipher-algo=aes128, unicode-mode=1'
        ) AS "pgp_enc_column"
    FROM
        "pgp_pass_cte"
)
SELECT
    "plain_original",
    "pgp_enc_column",
    -- pgp_sym_decrypt(msg bytea, psw text [, options text ]) returns text
    -- pgp_sym_decrypt_bytea(msg bytea, psw text [, options text ]) returns bytea
    pgp_sym_decrypt(
        "pgp_enc_column",
        "pgp_pass",
        'cipher-algo=aes128, unicode-mode=1'
    ) AS "plain_decrypted"
FROM
    "pgp_example_table_cte"
    CROSS JOIN "pgp_pass_cte"
```

See:

- https://www.postgresql.org/docs/current/pgcrypto.html#PGCRYPTO-PGP-ENC-FUNCS
