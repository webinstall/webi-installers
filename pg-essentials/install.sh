#!/bin/sh

__init_pg_essentials() {
    set -e
    set -u

    #########################
    # Install pg-essentials #
    #########################

    # Every package should define these 6 variables
    pkg_cmd_name="pg-essentials"

    pkg_dst_cmd="$HOME/.local/bin/psql-backup"
    pkg_dst="$pkg_dst_cmd"

    pkg_src_cmd="$HOME/.local/opt/pg-essentials-v$WEBI_VERSION/bin/psql-backup"
    pkg_src_bin="$HOME/.local/opt/pg-essentials-v$WEBI_VERSION/bin"
    pkg_src_dir="$HOME/.local/opt/pg-essentials-v$WEBI_VERSION"
    pkg_src="$pkg_src_cmd"

    pkg_install() {
        rm -rf "${pkg_src_dir}"
        # mv ./bnnanet-pg-essentials-* "$HOME/.local/opt/pg-essentials-v1.0.0"
        mv ./*"$pkg_cmd_name"*/ "${pkg_src_dir}"
    }

    pkg_link() {
        (
            cd ~/.local/opt/ || return 1
            rm -rf ./pg-essentials
            ln -s "pg-essentials-v$WEBI_VERSION" 'pg-essentials'
        )

        (
            mkdir -p ~/.local/bin/
            cd ~/.local/opt/pg-essentials/ || return 1
            for b_file in pg-*; do
                rm -rf ../../bin/"${b_file}"
                ln -s "../opt/pg-essentials-v$WEBI_VERSION/bin/${b_file}" .
            done
            for b_file in psql-*; do
                rm -rf ../../bin/"${b_file}"
                ln -s "../opt/pg-essentials-v$WEBI_VERSION/bin/${b_file}" .
            done
        )
    }

    pkg_get_current_version() {
        # 'psql-backup -V' has output in this format:
        #       psql-backup v1.0.0 - creates portable (across instances) SQL schema & data backups
        #
        #       USAGE
        #           psql-backup <user> [host] [port] [dbname]
        #
        #       ...
        # This trims it down to just the version number:
        #       1.0.0
        psql-backup --version 2> /dev/null | head -n 1 | cut -d' ' -f2 | sed 's:^v::'
    }

}

__init_pg_essentials
