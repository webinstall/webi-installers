---
title: Postgres
homepage: https://www.postgresql.org/
tagline: |
  PostgreSQL: The World's Most Advanced Open Source Relational Database.
---

To update or switch versions, run `webi postgres@stable` (or `@v10`, `@beta`,
etc).

### Files

These are the files / directories that are created and/or modified with this
install:

```text
~/.config/envman/PATH.env
~/.local/opt/postgres/
~/.local/share/postgres/var/postgresql.conf

# for psql (postgres client)
~/.pgpass
~/.psqlrc
~/.config/psql/
```

## Cheat Sheet

> Postgres is the all-in-one database for beginners and experts alike. It
> handles SQL, 'NoSQL', JSON, HSTORE, Full-Text Search, Messages Queues and
> more. Best bang for buck.

To enable Postgres as a Linux Service with [serviceman](../serviceman/): \
(see macOS below)

```sh
sudo env PATH="$PATH" \
    serviceman add --system --username "$(id -u -n)" --name 'postgres' -- \
    postgres -D ~/.local/share/postgres/var -p 5432

sudo systemctl restart systemd-journald
```

To login: \
(see creating remote app users below)

```sh
# as Postgres admin
psql "postgres://postgres:postgres@localhost:5432/postgres"

# as remote user
psql "postgres://db-xxxx@pg-1.example.com:5432/db-xxxx?sslmode=require&sslnegotiation=direct"
```

## Table of Contents

- Server vs Client & PG Essentials
- Initialize a database with a password
- Start the Postgres Server
  - development
  - systemd (most Linuxes)
  - OpenRC (container Linuxes)
  - macOS
- Enable Secure Remote Access
- Create Secure Remote App (User/DB)
- Change an User's (App's) password

### Where to Find the Postgres Client Cheat Sheet

This is exclusively a server-side cheat sheet.

For the client-side cheat sheet, see [The PSQL (Client) Cheat Sheet](../psql/).

For a collection of other helpful scripts, see
[PG Essentials](https://github.com/bnnanet/pg-essentials):

- pg-register-service
- pg-addgroup
- pg-adduser
- pg-passwd

### How to Initialize the Postgres Database (with password)

1. Create a database directory, paired to the Postgres version
   ```sh
   mkdir -p ~/.local/share/postgres-17/var/
   ```
2. Use a password file and `initdb` to create a new DB directory
   ```sh
   echo 'postgres' > /tmp/pwfile && \
   initdb -D ~/.local/share/postgres/var/ \
       --username 'postgres' --pwfile /tmp/pwfile \
       --auth-local=password --auth-host=password \ &&
   rm /tmp/pwfile
   ```
3. Test that the server starts
   ```sh
   postgres -D ~/.local/share/postgres/var -p 5432
   ```
   (kill with `ctrl+c`)

### How to run the Postgres server (daemon or foreground)

- foreground (development)
- systemd (Debian, Ubuntu, Redhat, etc)
- OpenRC (Alpine, Arch, Gentoo, etc)
- macOS (launchd)

#### To run in the foreground (for development):

```sh
postgres -D ~/.local/share/postgres/var -p 5432
```

#### Debian / Systemd

```sh
curl https://webi.sh/serviceman | sh
```

```sh
sudo env PATH="$PATH" \
    serviceman add --system --username "$(id -u -n)" --name 'postgres' -- \
    postgres -D ~/.local/share/postgres/var -p 5432

sudo systemctl restart systemd-journald
sudo journalctl -xefu postgres
```

#### Alpine / OpenRC

`/etc/init.d/postgres`:

```sh
#!/sbin/openrc-run

name="postgres"
description="postgres daemon"
command="/home/app/.local/opt/postgres/bin/postgres"
command_args="-D /home/app/.local/share/postgres/var -p 5432"
command_user="app:app"

supervisor="supervise-daemon"
output_log="/var/log/postgres"
error_log="/var/log/postgres"

depend() {
    need net
}

start_pre() {
    checkpath --directory --owner root /var/log/
    checkpath --file --owner ${command_user} ${output_log} ${error_log}
}

start() {
    ebegin "Starting ${name}"
    supervise-daemon ${name} --start \
        --stdout ${output_log} \
        --stderr ${error_log} \
        --pidfile /run/${RC_SVCNAME}.pid \
        --respawn-delay 5 \
        --respawn-max 10 \
        -- \
        ${command} \
        ${command_args} \
    eend $?
}

stop() {
    ebegin "Stopping ${name}"
    supervise-daemon ${name} --stop \
        --pidfile /run/${RC_SVCNAME}.pid
    eend $?
}
```

```sh
sudo rc-update add postgres
sudo rc-service postgres restart

sudo tail -f /var/log/postgres
```

#### macOS

```sh
serviceman add --name 'postgres' -- \
    postgres -D ~/.local/share/postgres/var -p 5432

tail -f ~/.local/share/postgres/var/log/postgres.log
```

### How to Enable Secure Remote Postgres Access

1. Create the `my_remote_users` group:

   ```sh
   echo 'CREATE ROLE "my_remote_users" NOLOGIN;' |
       psql "postgres://postgres:postgres@localhost:5432/postgres" -f -
   ```

2. Update the hba permissions to enable App users (`sameuser`): \
   `~/.local/share/postgres/var/pg_hba.conf`:

   ```ini
   # Allow 'my_remote_users' to connect remotely directly over the internet
   hostssl sameuser         +my_remote_users        0.0.0.0/0             scram-sha-256
   hostssl sameuser         +my_remote_users        ::0/0                 scram-sha-256

   # Allow 'my_remote_users' group to connect through a local TLS-terminating proxy
   hostnossl sameuser       +my_remote_users        127.0.0.1/8           scram-sha-256
   hostnossl sameuser       +my_remote_users        ::1/128               scram-sha-256
   host      sameuser       +my_remote_users        10.0.0.0/8            scram-sha-256
   host      sameuser       +my_remote_users        172.16.0.0/12         scram-sha-256
   host      sameuser       +my_remote_users        192.168.0.0/16        scram-sha-256
   host      sameuser       +my_remote_users        fc00::/7              scram-sha-256
   ```

3. Create a 10-year Self-signed cert for your server name or IP

   ```sh
   my_host=pg-1.example.com

   openssl req -new -x509 -days 3650 -nodes -text \
       -out ./server.crt -keyout ./server.key -subj "/CN=$my_host"

   chmod 0600 ./server.key ./server.crt
   mv ./server.key ./server.crt ~/.local/share/postgres/var/
   ```

4. Update the main postgres config to allow secure connections: \
   `~/.local/share/postgres/var/postgresql.conf`:

   ```ini
   ssl = on
   password_encryption = scram-sha-256
   listen_addresses = '*'
   ```

5. Restart Postgres for the change to take effect

   ```sh
   # all unixes
   killall postgres

   # systemd (Debian, Ubunut, RedHat, Suse, etc)
   sudo systemctl restart postgres

   # openrc (Alpine, Gentoo, Arch)
   rc-service postgres restart

   # macos
   launchctl unload ~/Library/LaunchAgents/postgres.plist
   launchctl load ~/Library/LaunchAgents/postgres.plist
   ```

### How to Create Secure Remote Users

The `sameuser` database directive REQUIRES the user and db name to be the same.

```sh
my_app="foobar_xxxx"

# e.g. generate password / token with 'xxd -l16 -ps /dev/urandom'
my_token="db-token-for-the-app"

echo "
   CREATE DATABASE \"$my_app\";
   CREATE ROLE \"$my_app\" LOGIN INHERIT
       IN ROLE \"my_remote_users\" ENCRYPTED PASSWORD '$my_token';
   GRANT ALL PRIVILEGES ON DATABASE \"$my_app\" to \"$my_app\";
" | psql "postgres://postgres:postgres@localhost:5432/postgres" -f -
```

Notes:

- quote style matters:
  - double quotes `"` for identifiers (users, tables, groups, roles)
  - single quotes `'` for values (password)

### How to Change a DB's Password

```sh
my_app='foobar_xxxx'
my_token="$(xxd -l16 -ps /dev/urandom)"

echo "ALTER USER \"$my_app\" PASSWORD '$my_token';" |
    psql 'postgres://postgres:postgres@localhost:5432/postgres' -f -
```
