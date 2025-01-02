---
title: pg-essentials
homepage: https://github.com/bnnanet/pg-essentials
tagline: |
  pg-essentials: client and server scripts for working with postgres
---

To update or switch versions, run `webi pg-essentials@stable` (or `@v1.0.0`,
`@beta`, etc).

### Files

These are the files / directories that are created and/or modified with this
install:

```text
~/.local/bin/
~/.local/opt/pg-essentials/
~/.pgpass
~/.psqlrc
~/.config/psql/psqlrc.sql
~/.config/psql/history
```

## Cheat Sheet

> `pg-essentials` includes scripts to manage credentials, backups, and
> preferences.

```sh
psql-store-credential 'postgres://my-userdb:my-token@my-host:5432/my-userdb'
psql-backup 'my-userdb'
psql-connect 'my-userdb'
psql-init TODO
```

```sh
pg-register-service '5432'
pg-addgroup 'hostssl' 'remote_users' 5432
pg-adduser 'my-user-prefix' '5432' 'remote_users'
pg-passwd 'my-user-prefix-and-suffix' 5432
```

### Client Scripts

#### How to Store Credentials

This will parse the PG URL and put it in the correct credential format in
`~/.pgpass`.

```sh
psql-store-credential 'postgres://my-userdb:my-token@my-host:5432/my-userdb'
```

This is the same as manually editing `~/.pgpass` to add

```text
# export PGPASSFILE="$HOME/.pgpass"
# hostname:port:database:username:password
my-host:5432:my-userdb:my-userdb:my-token
```

#### How to Connect

The `psql` only uses `~/.pgpass` to fill in the password.

`psql-connect` will lookup the userdb name in `~/.pgpass` and use the rest of
the connection details to connect (excluding the password, which will be read
from `~/.pgpass`).

```sh
psql-connect 'my-userdb'
```

This is the same as:

```sh
psql 'postgress://my-userdb@my-host:5432/my-userdb'
```

#### How to Backup

This uses `pg_dump` to create an easy-to-restore backup (using the correct
permission options), with the schema and data separated.

```sh
psql-backup 'my-userdb'
```

```text
my-userdb.schema.drop.sql  # drops and then creates schema
my-userdb.schema.sql       # creates schema, without dropping
my-userdb.data.sql         # inserts data
```

This is the same as:

```sh
pg_dump --no-privileges --no-owner --schema-only --clean \
    --username 'my-userdb' --no-password --host 'my-host' --port 5432 \
    -f ./my-userdb.schema.drop.sql 'my-userdb'

pg_dump --no-privileges --no-owner --schema-only \
    --username 'my-userdb' --no-password --host 'my-host' --port 5432 \
    -f ./my-userdb.schema.sql 'my-userdb'

pg_dump --no-privileges --no-owner --data-only \
    --username 'my-userdb' --no-password --host 'my-host' --port 5432 \
    -f ./my-userdb.data.sql 'my-userdb'
```

### Server Scripts

These assume a conflict-free installation of postgres at
`~/.local/share/postgres/var/`.

The scripts can easily be manually modified for other locations.

#### How to Register Service

```sh
pg-register-service '5432'
```

This is the same as

```sh
curl https://webi.sh/serviceman | sh
source ~/.config/envman/PATH.env

mkdir -p ~/.local/share/postgres
serviceman add --name 'postgres' -- \
    postgres -D ~/.local/share/postgres/var -p 5432
```

#### How to add Remote Role (Group)

This will add a role (group) which allows users (named the same as their
database name) to access the pg database remotely, using TLS with SNI (ALPN will
be set to 'postgresql' and must be explicitly accepted by proxies).

```sh
pg-addgroup 'hostssl' 'remote_users' 5432
```

This is the same as adding a remote users role and editing
`~/.local/share/postgres/var/pg_hba.conf`

```sql
CREATE ROLE "remote_users" NOLOGIN;
```

```ini
hostssl sameuser         +remote_users        0.0.0.0/0               scram-sha-256
hostssl sameuser         +remote_users        ::0/0                   scram-sha-256
```

#### How to add Remote User

This will create a user and database of the same name, with the given prefix
(followed by a random suffix), as a member of 'remote_users':

```sh
pg-adduser 'my-user-prefix'
```

This is the same as generating a random suffix and password (ex: using `uuidgen`
or `xxd -l 16 -ps /dev/urandom`), and creating the `DATABASE`, `ROLE`, and
granting `PRIVILEGES`:

```sql
CREATE DATABASE "my-user-prefix-1234";
CREATE ROLE "my-user-prefix-1234" LOGIN INHERIT IN ROLE "remote_users" ENCRYPTED PASSWORD 'supersecret';
GRANT ALL PRIVILEGES ON DATABASE "my-user-prefix-1234" to "my-user-prefix-1234";
```

Note: the password is NOT encrypted, just hashed - a misnomer from days of yore

#### How to Set a User's Password

This generates a new random password for the user/db.

```sh
pg-passwd 'my-user-prefix-and-suffix'
```

This is the same as generating a random password and running the following:

```sql
ALTER USER "my-user-prefix-and-suffix" WITH PASSWORD 'supersecret';
```

### Building Postgres from Source

These scripts will build postgres in `~/relocatable`, from source.

```sh
pg-build-linux "$(hostname)" 17.2
pg-build-macos "$(hostname)" 17.2
```
