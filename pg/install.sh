#!/bin/sh
# shellcheck disable=SC2034

__init_pg() {
    set -e
    set -u

    ##################################
    # Install postgres server+client #
    ##################################

    # Every package should define these 6 variables
    pkg_cmd_name="postgres"

    pkg_dst_cmd="${HOME}/.local/opt/postgres/bin/postgres"
    pkg_dst_bin="${HOME}/.local/opt/postgres/bin"
    pkg_dst_dir="${HOME}/.local/opt/postgres"
    pkg_dst="${pkg_dst_dir}"

    pkg_src_cmd="${HOME}/.local/opt/postgres-v${WEBI_VERSION}/bin/postgres"
    pkg_src_dir="${HOME}/.local/opt/postgres-v${WEBI_VERSION}"
    pkg_src="${pkg_src_dir}"

    POSTGRES_DATA_DIR=$HOME/.local/share/postgres/var

    pkg_get_current_version() {
        # 'postgres --version' has output in this format:
        #       postgres (PostgreSQL) 17.0
        # This trims it down to just the version number:
        #       17.0
        postgres --version 2> /dev/null | head -n 1 | cut -d' ' -f3
    }

    pkg_install() {
        # mkdir -p $HOME/.local/opt
        mkdir -p "$(dirname "$pkg_src")"

        # mv ./postgres-17 "$HOME/.local/opt/postgres-v17.0"
        mv ./"postgres-"* "$pkg_src"
    }

    pkg_post_install() {
        webi_path_add "$pkg_dst_bin"

        #echo "Initializing PostgreSQL with database at $POSTGRES_DATA_DIR/"

        PWFILE="$(pwd)/pwfile.tmp"
        mkdir -p "$POSTGRES_DATA_DIR"
        chmod 0700 "$POSTGRES_DATA_DIR"

        if ! test -f "$POSTGRES_DATA_DIR/postgresql.conf"; then
            echo "postgres" > "$PWFILE"
            "$pkg_src/bin/initdb" \
                -D "$POSTGRES_DATA_DIR/" \
                --username postgres --pwfile "$PWFILE" \
                --auth-local=password --auth-host=password
        fi
    }

    pkg_done_message() {
        # TODO show with serviceman
        echo "    Installed $(t_pkg "$pkg_cmd_name v$WEBI_VERSION") (and $(t_pkg "psql")) to $(t_link "$(fn_sub_home "${pkg_dst_bin}")")"
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
}

__init_pg
