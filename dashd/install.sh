#!/bin/sh

# shellcheck disable=SC2034,2317
# "'pkg_cmd_name' appears unused. Verify it or export it."
# "Command appears to be unreachable."

__init_dashd() {
    set -e
    set -u

    #################
    # Install dashd #
    #################

    # Every package should define these 6 variables
    pkg_cmd_name="dashd"

    pkg_dst_cmd="$HOME/.local/opt/dashcore/bin/dashd"
    pkg_dst_dir="$HOME/.local/opt/dashcore"
    pkg_dst="$pkg_dst_dir"

    pkg_src_cmd="$HOME/.local/opt/dashcore-v$WEBI_VERSION/bin/dashd"
    pkg_src_dir="$HOME/.local/opt/dashcore-v$WEBI_VERSION"
    pkg_src="$pkg_src_dir"

    # pkg_install must be defined by every package
    pkg_install() {
        # mv ./dashcore-* ~/.local/opt/dashcore-v0.19.1
        mv ./dashcore-* "${pkg_src_dir}"

        if ! test -e "${HOME}/.dashcore"; then
            mkdir -p "${HOME}/.dashcore"
            chmod 0700 "${HOME}/.dashcore"
        fi
        if ! test -e "${HOME}/.dashcore/dash.conf"; then
            touch "${HOME}/.dashcore/dash.conf"
            chmod 0600 "${HOME}/.dashcore/dash.conf"
        fi
        if ! grep -q rpcuser "${HOME}/.dashcore/dash.conf"; then
            my_main_pass="$(xxd -l16 -ps /dev/urandom)"
            my_test_pass="$(xxd -l16 -ps /dev/urandom)"
            {
                echo '[main]'
                echo "rpcuser=$(id -u -n)"
                echo "rpcpassword=${my_main_pass}"
                echo ''
                echo '[test]'
                echo "rpcuser=$(id -u -n)-test"
                echo "rpcpassword=${my_test_pass}"
                echo ''
            } >> "${HOME}/.dashcore/dash.conf"
        fi

        # Always try to correct the permissions due to
        # https://github.com/dashpay/dash/issues/5420
        chmod -R og-rwx "${HOME}/.dashcore/" || true

        echo "WEBI_HOST: $WEBI_HOST"
        if ! test -e "$HOME/.local/bin/dashd-hd"; then
            webi_download \
                "$WEBI_HOST/packages/dashd/dashd-hd" \
                "$HOME/.local/bin/dashd-hd"
            chmod a+x "$HOME/.local/bin/dashd-hd"
        fi
        if ! test -e "$HOME/.local/bin/dashd-testnet"; then
            webi_download \
                "$WEBI_HOST/packages/dashd/dashd-testnet" \
                "$HOME/.local/bin/dashd-testnet"
            chmod a+x "$HOME/.local/bin/dashd-testnet"
        fi

        webi_download \
            "$WEBI_HOST/packages/dashd/dashd-hd-service-install" \
            "$HOME/.local/bin/dashd-hd-service-install"
        chmod a+x "$HOME/.local/bin/dashd-hd-service-install"

        webi_download \
            "$WEBI_HOST/packages/dashd/dashd-testnet-service-install" \
            "$HOME/.local/bin/dashd-testnet-service-install"
        chmod a+x "$HOME/.local/bin/dashd-testnet-service-install"
    }

    pkg_done_message() {
        echo "Installed 'dashd@v$WEBI_VERSION' to ~/.local/opt/dashcore/"
        echo ""
        echo "TO START THE DAEMON"
        echo ""
        echo "        # mainnet"
        echo "        dashd-hd-service-install"
        echo ""
        echo ""
        echo "        # testnet"
        echo "        dashd-testnet-service-install"
        echo ""
    }

    # pkg_get_current_version is recommended, but not required
    pkg_get_current_version() {
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

__init_dashd
