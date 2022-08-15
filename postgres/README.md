---
title: Postgres
homepage: https://www.postgresql.org/
tagline: |
  PostgreSQL: The World's Most Advanced Open Source Relational Database.
---

To update or switch versions, run `webi postgres@stable` (or `@v10`, `@beta`,
etc).

## Cheat Sheet

> Postgres is the all-in-one database for beginners and experts alike. It
> handles SQL, 'NoSQL', JSON, HSTORE, Full-Text Search, Messages Queues and
> more. Best bang for buck.

### Start the postgres server

Run just once (for development):

```sh
postgres -D $HOME/.local/share/postgres/var -p 5432
```

Run as a system service on Linux:

```sh
sudo env PATH="$PATH" \
    serviceman add --system --username "$(whoami)" --name postgres -- \
    postgres -D "$HOME/.local/share/postgres/var" -p 5432

# Restart the logging service
sudo systemctl restart systemd-journald
```

### Connect with the psql client

```sh
psql 'postgres://postgres:postgres@localhost:5432/postgres'
```

### Initialize a database with a password

```sh
echo "postgres" > /tmp/pwfile
mkdir -p $HOME/.local/share/postgres/var/

initdb -D $HOME/.local/share/postgres/var/ \
    --username postgres --pwfile "/tmp/pwfile" \
    --auth-local=password --auth-host=password

rm /tmp/pwfile
```

### Add and secure remote users

1. Set your server name or IP address
   ```sh
   PG_HOST=pg-1.example.com
   ```
2. Generate a 10-year self-signed TLS certificate

   ```sh
   openssl req -new -x509 -days 3650 -nodes -text \
       -out server.crt \
       -keyout server.key \
       -subj "/CN=$PG_HOST"

   chmod og-rwx server.key server.crt
   mv server.key server.crt ~/.local/share/postgres/var/
   ```

3. Enable SSL (TLS)
   ```sh
   vim ~/.local/share/postgres/var/postgresql.conf
   ```
   ```ini
   ssl = on
   password_encryption = scram-sha-256
   listen_addresses = '*'
   ```
4. Generate a user with a random token password

   ```sh
   MY_USER='my_user'
   MY_PASSWORD="$(xxd -l16 -ps /dev/urandom)"

   echo "CREATE ROLE \"$MY_USER\" LOGIN ENCRYPTED PASSWORD '$MY_PASSWORD';" |
       psql 'postgres://postgres:postgres@localhost:5432/postgres' -f -
   ```

5. Show the token password and save it somewhere
   ```sh
   echo "$MY_PASSWORD"
   ```
6. Allow the user to connect via IPv4 and IPv6
   ```sh
   echo "# Allow $MY_USER to connect remotely over the internet
   hostssl all             $MY_USER        0.0.0.0/0               scram-sha-256
   hostssl all             $MY_USER        ::0/0                   scram-sha-256" \
       >> ~/.local/share/postgres/var/pg_hba.conf
   ```
7. Restart postgres
   ```sh
   sudo systemctl restart postgres
   ```
8. Test the connection from a remote system

   ```sh
   PG_HOST="pg-1.example.com"
   PG_USER="my_user"

   psql "postgres://$PG_USER@$PG_HOST/postgres?sslmode=require" << EOF
   SELECT CURRENT_USER;
   EOF
   ```

   (you will be prompted for your password / token)

### Add or update a user's password

```sh
MY_USER='my_user'
MY_NEW_PASSWORD="$(xxd -l16 -ps /dev/urandom)"

# Update existing user with new password using new hash
echo "ALTER USER \"$MY_USER\" PASSWORD '$MY_NEW_PASSWORD';" |
    psql 'postgres://postgres:postgres@localhost:5432/postgres' -f -
```
