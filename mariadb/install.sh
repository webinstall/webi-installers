#!/bin/sh
# shellcheck disable=SC2034

__init_mariadb() {
    set -e
    set -u

    ###################
    # Install mariadb #
    ###################

    # Every package should define these 6 variables
    pkg_cmd_name="mariadb"

    pkg_dst_cmd="${HOME}/.local/opt/mariadb/bin/mariadb"
    pkg_dst_bin="${HOME}/.local/opt/mariadb/bin"
    pkg_dst_dir="${HOME}/.local/opt/mariadb"
    pkg_dst="${pkg_dst_dir}"

    pkg_src_cmd="${HOME}/.local/opt/mariadb-v${WEBI_VERSION}/bin/mariadb"
    pkg_src_dir="${HOME}/.local/opt/mariadb-v${WEBI_VERSION}"
    pkg_src="${pkg_src_dir}"

    pkg_get_current_version() {
        # 'mariadb --version' has output in this format:
        #       mariadb (mariadbQL) 17.0
        # This trims it down to just the version number:
        #       17.0
        mariadb --version 2> /dev/null | head -n 1 | cut -d' ' -f3
    }

    pkg_install() {
        # mkdir -p $HOME/.local/opt
        mkdir -p "$(dirname "$pkg_src")"

        # mv ./mariadb-11.4.4-linux-systemd-x86_64 "$HOME/.local/opt/mariadb-v11.4.4"
        mv ./"mariadb-"* "$pkg_src"
    }

    pkg_link() {
        # ln -s "$HOME/.local/opt/mariadb-v17.0" "$HOME/.local/opt/mariadb"
        # for the old mariadb version
        ln -s "$pkg_src" "$pkg_dst"
        if ! test -d ~/.local/opt/mysql; then
            rm -f ~/.local/opt/mysql
            ln -s "mariadb-v${WEBI_VERSION}" ~/.local/opt/mysql
        fi
    }

    #shellcheck disable=SC2059
    pkg_post_install() {
        b_hostname="$(hostname)"

        if ! test -e ~/.config/mariadb; then
            mkdir -p ~/.config/mariadb
            chmod 0700 ~/.config/mariadb/
        fi

        if ! test -e ~/.local/share/mariadb; then
            mkdir -p ~/.local/share/mariadb/
            chmod 0700 ~/.local/share/mariadb/
            mkdir -p ~/.local/share/mariadb/run/
            chmod 0750 ~/.local/share/mariadb/run/
            mkdir -p ~/.local/share/mariadb/var/
            chmod 0750 ~/.local/share/mariadb/var/
        else
            mkdir -p ~/.local/share/mariadb/run/
            mkdir -p ~/.local/share/mariadb/data/
            mkdir -p ~/.local/share/mariadb/var/
        fi

        printf "    $(t_path '~''/.my.cnf') $(t_dim '(sources client & server config)') "
        if test -e ~/.my.cnf; then
            printf -- "$(t_dim 'Found')\n"
        else
            {
                echo '[client]'
                echo '!include /home/app/.config/mariadb/my.cnf'
                echo ''
                echo '[server]'
                echo '!include /home/app/.local/share/mariadb/my.cnf'
            } > ~/.my.cnf
            printf -- "Created\n"
        fi

        printf "    $(t_path '~''/.config/mariadb/my.cnf') $(t_dim '(client config)') "
        if test -e ~/.config/mariadb/my.cnf; then
            printf -- "$(t_dim 'Found')\n"
        else
            {
                echo '[client]'
                echo '    default-character-set   = utf8mb4'
                echo ''
                echo "    socket                  = $HOME/.local/share/mariadb/run/mariadbd.sock"
                echo "    #host                    = ${b_hostname}"
                echo '    #port                    = 3306'
                echo "    #user                    = ${USER}"
                echo "    #password                = (none)"
                echo "    #database                = (none)"
            } > ~/.config/mariadb/my.cnf
            printf -- "Created\n"
        fi

        printf "    $(t_path '~''/.local/share/mariadb/my.cnf') $(t_dim '(server config)') "
        if test -e ~/.local/share/mariadb/my.cnf; then
            printf -- "$(t_dim 'Found')\n"
        else
            {
                echo '[server]'
                echo "    character-set-server    = utf8mb4"
                echo "    collation-server        = utf8mb4_unicode_ci"
                echo "    init-connect            = 'SET NAMES utf8mb4'"
                echo ''
                echo "    bind-address            = 127.0.0.1"
                echo "    port                    = 3306"
                echo "    socket                  = $HOME/.local/share/mariadb/run/mariadbd.sock"
                echo ''
                echo "    basedir                 = $HOME/.local/opt/mariadb/"
                echo "    datadir                 = $HOME/.local/share/mariadb/data/"
                echo "    pid-file                = $HOME/.local/share/mariadb/run/mariadbd.pid"
                echo "    #log-error               = $HOME/.local/share/mariadb/var/error.log"
            } > ~/.local/share/mariadb/my.cnf
            printf -- "Created\n"
        fi

        printf "    $(t_path '~''/.local/share/mariadb/data/') $(t_dim '(database)') "
        if test -e ~/.local/share/mariadb/data; then
            printf -- "$(t_dim 'Found')\n"
        else
            printf -- "Initializing ... "
            mkdir -p ~/.local/share/mariadb/data/
            chmod 0700 ~/.local/share/mariadb/data/
            # echo ""
            # echo "    Consider joining MariaDB's strong and vibrant community:"
            # echo "        https://mariadb.org/get-involved/"
            # echo ""
            ~/.local/opt/mariadb/scripts/mariadb-install-db --defaults-file="$HOME/.my.cnf" > /dev/null
            printf -- "OK\n"
        fi
        webi_path_add "$(dirname "$pkg_dst_cmd")"
    }

    pkg_done_message() {
        b_hostname="$(hostname)"

        echo ""
        echo "    Installed $(t_pkg "mariadb") $(t_dim "(mysql)") as $(t_link '~''/.local/opt/mariadb/bin/mariadb')"

        echo ""
        echo "To run manually"
        echo "    $(t_cmd 'mariadbd-safe') --defaults-file=\"$(t_path "$HOME/.my.cnf")\""
        #mariadbd-safe --defaults-file=$HOME/.my.cnf --print-defaults
        echo ""
        echo "To install as a system service"
        # export MARIADB_HOME=$HOME/.local/opt/mariadb/
        echo "    $(t_cmd 'serviceman') add --name mariadb --workdir $(t_path '~''/.local/opt/mariadb/') -- \\"
        echo "        $(t_cmd 'mariadbd') --defaults-file=\"$(t_path "$HOME/.my.cnf")\""
        echo ""
        echo "To connect with a client:"
        echo "    $(t_cmd 'mariadb') -u 'root' -h 'localhost' $(t_dim '# all-privileges admin')"
        echo "    $(t_cmd 'mariadb') -u '${USER}' -h 'localhost' $(t_dim '# all-privileges admin')"
    }
}

__init_mariadb
