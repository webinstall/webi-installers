#!/bin/sh

# shellcheck disable=SC2034
# "'pkg_cmd_name' appears unused. Verify it or export it."

__init_dashcore() {
    set -e
    set -u

    ####################
    # Install dashcore #
    ####################

    # Every package should define these 6 variables
    pkg_cmd_name="dash-qt"

    pkg_dst_cmd="$HOME/.local/opt/dashcore/bin/dash-qt"
    pkg_dst_dir="$HOME/.local/opt/dashcore"
    pkg_dst="$pkg_dst_dir"

    pkg_src_cmd="$HOME/.local/opt/dashcore-v$WEBI_VERSION/bin/dash-qt"
    pkg_src_dir="$HOME/.local/opt/dashcore-v$WEBI_VERSION"
    pkg_src="$pkg_src_dir"

    # pkg_install must be defined by every package
    pkg_install() {
        # mv ./dashcore-* ~/.local/opt/dashcore-v0.19.1
        mv ./dashcore-* "${pkg_src_dir}"

        if ! test -e "${HOME}/.dashcore"; then
            mkdir -p "${HOME}/.dashcore"
            chmod 0700 "${HOME}/.dashcore" || true
        fi

        # if ! test -e "${HOME}/.dashcore/dash.conf"; then
        #     my_main_pass="$(xxd -l16 -ps /dev/urandom)"
        #     my_test_pass="$(xxd -l16 -ps /dev/urandom)"
        #     {
        #         echo '[main]'
        #         echo "rpcuser=$(id -u -n)"
        #         echo "rpcpassword=${my_main_pass}"
        #         echo ''
        #         echo '[test]'
        #         echo "rpcuser=$(id -u -n)-test"
        #         echo "rpcpassword=${my_test_pass}"
        #         echo ''
        #     } >> "${HOME}/.dashcore/dash.conf"
        #     chmod 0600 "${HOME}/.dashcore/dash.conf" || true
        # fi

        # if ! test -e "${HOME}/.dashcore/settings.json"; then
        #     echo '{}' >> "${HOME}/.dashcore/settings.json"
        #     chmod 0600 "${HOME}/.dashcore/settings.json" || true
        # fi

        if ! test -e "$HOME/.local/bin/dash-qt-hd" ||
            ! test -e "$HOME/.local/bin/dash-qt-testnet"; then

            "$HOME/.local/bin/webi" dashcore-utils
        fi

        # Always try to correct the permissions due to
        # https://github.com/dashpay/dash/issues/5420
        chmod -R og-rwx "${HOME}/.dashcore/" || true
    }

    # pkg_get_current_version is recommended, but not required
    pkg_get_current_version() {
        # 'dash-qt' doesn't have version info, so we use 'dashd'
        # 'dashd --version' has output in this format:
        #       Dash Core Daemon version v19.1.0
        # This trims it down to just the version number:
        #       19.1.0
        dashd --version 2> /dev/null |
            head -n 1 |
            cut -d ' ' -f 5 |
            sed 's:^v::'
    }
}

__init_dashcore
