#!/bin/sh

set -e
set -u

pkg_cmd_name="postgres"
#WEBI_SINGLE=""

POSTGRES_DATA_DIR=$HOME/.local/share/postgres/var

pkg_get_current_version() {
    # 'postgres --version' has output in this format:
    #       postgres (PostgreSQL) 10.13
    # This trims it down to just the version number:
    #       10.13
    postgres --version 2> /dev/null | head -n 1 | cut -d' ' -f3
}

pkg_install() {
    # mkdir -p $HOME/.local/opt
    mkdir -p "$(dirname "$pkg_src")"

    # mv ./pgqsl* "$HOME/.local/opt/postgres-v10.13"
    mv ./"p"* "$pkg_src"
}

pkg_link() {
    # rm -f "$HOME/.local/opt/postgres"
    rm -f "$pkg_dst"
    rm -f "$HOME/Applications/pgAdmin"*.app || true
    rm -f "/Applications/pgAdmin"*.app || true

    # ln -s "$HOME/.local/opt/postgres-v10.13" "$HOME/.local/opt/postgres"
    ln -s "$pkg_src" "$pkg_dst"
    if [ "Darwin" = "$(uname -s)" ]; then
        mkdir -p /Applications
        ln -s "$pkg_src/pgAdmin 4.app" "/Applications/pgAdmin 4.app" || true
        if [ -e "$pkg_src/pgAdmin 4.app/Contents/Resources/venv/lib/libpython3.8.dylib" ]; then
            # a simple patch to fix the bad link in the package
            rm "$pkg_src/pgAdmin 4.app/Contents/Resources/venv/lib/libpython3.8.dylib"
            ln -s "../../../Frameworks/Python" "$pkg_src/pgAdmin 4.app/Contents/Resources/venv/lib/libpython3.8.dylib"
        fi
    fi
}

pkg_post_install() {
    webi_path_add "$pkg_dst_bin"

    #echo "Initializing PostgreSQL with database at $POSTGRES_DATA_DIR/"

    PWFILE="$(pwd)/pwfile.tmp"
    mkdir -p "$POSTGRES_DATA_DIR"
    chmod 0700 "$POSTGRES_DATA_DIR"

    if [ ! -f "$POSTGRES_DATA_DIR/postgresql.conf" ]; then
        echo "postgres" > "$PWFILE"
        "$pkg_src/bin/initdb" \
            -D "$POSTGRES_DATA_DIR/" \
            --username postgres --pwfile "$PWFILE" \
            --auth-local=password --auth-host=password
    fi
}

pkg_done_message() {
    # TODO show with serviceman
    echo "Installed 'postgres' and 'psql' at $pkg_dst"
    echo ""
    echo "IMPORTANT!!!"
    echo ""
    echo "Database initialized at $POSTGRES_DATA_DIR:"
    echo "    postgres -D $POSTGRES_DATA_DIR -p 5432"
    echo ""
    echo "Username and password set to 'postgres':"
    echo "    psql 'postgres://postgres:postgres@localhost:5432/postgres'"
    echo ""
}
