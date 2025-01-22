---
title: MariaDB (MySQL)
homepage: https://mariadb.com/
tagline: |
  MariaDB: The original MySQL, renamed due to Oracle acquiring the trademark
---

To update or switch versions, run `webi mariadb@stable` (or `@v11`, `@lts`,
etc).

### Files

These are the files / directories that are created and/or modified with this
install:

```text
~/.config/envman/PATH.env
~/.local/opt/mariadb/
~/.local/share/mariadb/
~/.my.cnf
~/.config/mariadb/my.cnf
~/.local/share/mariadb/my.cnf
```

## Cheat Sheet

> MariaDB is the original authors' successor to MySQL, after Oracle's
> acquisition of the MySQL trademark. Although [Postgres](../postgres/) is
> generally recommended for new projects, projects that previously used MySQL or
> MariaDB can continue to gain benefit from the continued development of
> MariaDB.

Connect as the default admin, the root admin, or a remote (`%`) user:

```sh
mysql 'dbname'
sudo mysql -u root 'dbname'
mysql -u 'dbuser' -p -h '127.0.0.1' -P 3306 'dbname'
```

Manage MariaDB as a system service with [serviceman](../serviceman/):

```sh
curl https://webi.sh/serviceman | sh

# Linux and macOS
serviceman add --name 'mysqld' --workdir ~/.local/opt/mariadb/ -- \
    mariadbd --defaults-file="$HOME/.local/share/mariadb/my.cnf"

# On Linux, with systemd
sudo systemctl restart systemd-journald
sudo systemctl restart 'mysqld'
sudo journalctl -xef --unit 'mysqld'
```

## Table of Contents

- Use UTF-8 (not Swedish)
- Vertical Rows
- Create an App User and DB
- Backup and Restore
- Connect via SSH Proxy
- Remove default users

### Switch from Swedish to UTF-8

This is done automatically if installed by Webi, and in MariaDB 11.6+.

Edit your `my.cnf` files as follows:

```sh
[server]
    character-set-server    = utf8mb4
    collation-server        = utf8mb4_unicode_ci
    init-connect            = 'SET NAMES utf8mb4'
```

```sh
[client]
    default-character-set   = utf8mb4
```

You can then update old tables:

```sql
ALTER DATABASE your_database_name CHARACTER SET = utf8mb4 COLLATE = utf8mb4_unicode_ci;
```

See <https://chatgpt.com/c/67941f5a-9390-800e-86e7-2e8bd56117f7>.

In some cases it may be simpler better to **backup and restore** (see table of
contents) the databases due to foreign key constraints.

### How to View Rows Vertically

Use `\G` instead of `;` for a single query

```sh
SELECT * FROM `mysql`.`global_priv` \G
```

### How to Create an App User + DB

You create a database, a user (typically of the same name), a password
(typically random via `xxd` or <https://pw.bnna.net>), and grant the app admin
privileges on its database.

```sql
USE `mysql`;
CREATE DATABASE `appdb`;
CREATE USER 'appuser'@'%' IDENTIFIED BY 'super-secret';
GRANT ALL PRIVILEGES ON `appdb`.* TO 'appuser'@'%';
FLUSH PRIVILEGES;
```

Here's a script for doing the same:

```sh
mariadb-create-app 'foobar'
```

```sh
#!/bin/sh
set -e
set -u

# USAGE
#     mariadb-create-app [app-name]
#
# EXAMPLE
#     mariadb-create-app 'foobar'

main() {(
    b_appname="${1:-$(hostname)}"

    b_dbname="${b_appname}"
    b_user="${b_dbname}"
    b_password="$(xxd -l8 -p /dev/urandom | sed 's/..../&-/g; s/-$//')"

    mariadb -e "
        USE \`mysql\`;
        CREATE DATABASE IF NOT EXISTS \`${b_dbname}\`;
        CREATE USER '${b_user}'@'%' IDENTIFIED BY '${b_password}';
        GRANT ALL PRIVILEGES ON \`${b_dbname}\`.* TO '${b_user}'@'%';
        FLUSH PRIVILEGES;
    "

    echo "${b_password}" > ./"${b_appname}-password.txt"

    echo ""
    echo "Password in ./${b_appname}-password.txt"
    echo ""
    echo "mysql://${b_user}:********@localhost:3306/${b_dbname}"
    echo "mariadb -u ${b_user} -p ${b_dbname}"
    echo ""
)}
```

### How to Backup and Restore

Backup a single database:

```sh
my_ts="$(date "+%F_%H.%M.%S")"
mysqldump -u username -p --force --hex-blob --databases 'dbname' \
 --triggers --routines --events \
    --add-drop-table --add-drop-triggers \
    --skip-set-charset --single-transaction > ./"backup.${ts}.sql"
```

Notes:

- `--force` **is always necessary** and should be the default - it will continue
  the backup in the case that inconsistencies are found - such as a _View_
  referencing a column that no longer exists (which is not checked during
  `ALTER TABLE`)
- `--skip-set-charset` to accept the default `utf8` rather than accidentally
  recreating tables as legacy `latin1-swedish`
- `--add-drop-table` and `--add-drop-triggers` do not need to be used if your
  user has the ability to drop and recreate the database
- `--databases 'dbname'` omits ``USE `dbname`;``, which allows you to easily
  restore to a different database name

Destructive Restore (drop that database and then restore it):

```sh
mysql -u username -p -e 'DROP DATABASE `dbname`';
mysql -u username -p 'dbname' < ./backup.sql
```

### Connect via SSH Proxy

1. Create a proxy (ignore warnings)
   ```sh
   #ssh user@server -fnNT -L <local-port>:<remote-host>:<remote-port>
   ssh ${USER}@${b_hostname} -fnNT -L 13306:localhost:3306
   ```
2. Connect via `mysql`, `mariadb`, Sequel Ace, etc:
   ```sh
   mysql -u remote-user -h 127.0.0.1 -P 13306
   ```

**Notes**

- connect with a user that has the host `%` and DOES NOT have a `localhost` or
  `127.0.0.1` entry - otherwise the client may "upgrade" to a socket connection
  and fail.
- you may need to remove the wildcard `localhost` users (see below)

### Remove Default Access `localhost` Users

You may not be able to connect via an SSH proxy if the default users exist. \
(it may match `` `%`@`localhost` `` instead of `` `app`@`%` `` and deny the
password)

```sql
USE `mysql`;
DELETE FROM `global_priv` WHERE `User` = '';
FLUSH PRIVILEGES;
```
