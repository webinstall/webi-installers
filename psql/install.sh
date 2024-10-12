#!/bin/sh
# shellcheck disable=SC2034

__init_psql() {
    set -e
    set -u

    ##################################
    # Install psql (postgres client) #
    ##################################

    # Every package should define these 6 variables
    pkg_cmd_name="psql"

    pkg_dst_cmd="${HOME}/.local/opt/psql/bin/psql"
    pkg_dst_dir="${HOME}/.local/opt/psql"
    pkg_dst="${pkg_dst_dir}"

    pkg_src_cmd="${HOME}/.local/opt/psql-v${WEBI_VERSION}/bin/psql"
    pkg_src_dir="${HOME}/.local/opt/psql-v${WEBI_VERSION}"
    pkg_src="${pkg_src_dir}"

    pkg_get_current_version() {
        # 'psql --version' has output in this format:
        #       psql (PostgreSQL) 17.0
        # This trims it down to just the version number:
        #       17.0
        psql --version 2> /dev/null | head -n 1 | cut -d' ' -f3
    }

    pkg_install() {
        # mkdir -p $HOME/.local/opt
        mkdir -p "$(dirname "$pkg_src")"

        # mv ./psql-17 "$HOME/.local/opt/psql-v17.0"
        mv ./"psql-"* "$pkg_src"

        # initdb is mistakenly included with the client libs
        rm -f "$pkg_src_dir"/bin/initdb
        rm -f "$pkg_dst_dir"/bin/initdb
    }

    pkg_done_message() {
        echo "    Installed $(t_pkg "$pkg_cmd_name v$WEBI_VERSION") as $(t_link "$(fn_sub_home "${pkg_dst_cmd}")")"
        echo ""
        echo "Connect to PostgreSQL database with the default username and password:"
        echo "    psql 'postgres://postgres:postgres@localhost:5432/postgres'"
        echo ""
    }
}

__init_psql
