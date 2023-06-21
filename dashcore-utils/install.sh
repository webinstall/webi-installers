#!/bin/sh
set -e
set -u

__install_dashcore_utils() {
    webi_download \
        "$WEBI_HOST/packages/dashcore-utils/dash-qt-hd" \
        "$HOME/.local/bin/dash-qt-hd"
    chmod a+x "$HOME/.local/bin/dash-qt-hd"

    webi_download \
        "$WEBI_HOST/packages/dashcore-utils/dash-qt-testnet" \
        "$HOME/.local/bin/dash-qt-testnet"
    chmod a+x "$HOME/.local/bin/dash-qt-testnet"

    webi_download \
        "$WEBI_HOST/packages/dashcore-utils/dashd-hd" \
        "$HOME/.local/bin/dashd-hd"
    chmod a+x "$HOME/.local/bin/dashd-hd"

    webi_download \
        "$WEBI_HOST/packages/dashcore-utils/dashd-testnet" \
        "$HOME/.local/bin/dashd-testnet"
    chmod a+x "$HOME/.local/bin/dashd-testnet"

    webi_download \
        "$WEBI_HOST/packages/dashcore-utils/dashd-hd-service-install" \
        "$HOME/.local/bin/dashd-hd-service-install"
    chmod a+x "$HOME/.local/bin/dashd-hd-service-install"

    webi_download \
        "$WEBI_HOST/packages/dashcore-utils/dashd-testnet-service-install" \
        "$HOME/.local/bin/dashd-testnet-service-install"
    chmod a+x "$HOME/.local/bin/dashd-testnet-service-install"

    if ! test -e "${HOME}/.dashcore"; then
        mkdir -p "${HOME}/.dashcore"
        chmod 0700 "${HOME}/.dashcore"
    fi
    if ! test -e "${HOME}/.dashcore/dash.conf"; then
        touch "${HOME}/.dashcore/dash.conf"
        chmod 0600 "${HOME}/.dashcore/dash.conf"
    fi

    webi_download \
        "$WEBI_HOST/packages/dashcore-utils/dash.example.conf" \
        "$HOME/.dashcore/dash.example.conf"

    if ! grep -q rpcuser ~/.dashcore/dash.conf; then
        cat ~/.dashcore/dash.example.conf >> ~/.dashcore/dash.conf

        cmd_sed="sed -i -E"
        my_bsd_sed=''
        if ! sed -V 2>&1 | grep -q 'GNU'; then
            cmd_sed="sed -i .dascore-utils-bak -E"
            my_bsd_sed='true'
        fi

        my_user="$(
            id -u -n
        )"
        my_main_pass="$(xxd -l16 -ps /dev/urandom)"
        my_test_pass="$(xxd -l16 -ps /dev/urandom)"
        my_regtest_pass="$(xxd -l16 -ps /dev/urandom)"

        $cmd_sed "s/RPCUSER_MAIN/${my_user}/" ~/.dashcore/dash.conf
        $cmd_sed "s/RPCPASS_MAIN/${my_main_pass}/" ~/.dashcore/dash.conf

        $cmd_sed "s/RPCUSER_TEST/${my_user}-test/" ~/.dashcore/dash.conf
        $cmd_sed "s/RPCPASS_TEST/${my_test_pass}/" ~/.dashcore/dash.conf

        $cmd_sed "s/RPCUSER_REGTEST/${my_user}-regtest/" ~/.dashcore/dash.conf
        $cmd_sed "s/RPCPASS_REGTEST/${my_regtest_pass}/" ~/.dashcore/dash.conf

        if test -n "${my_bsd_sed}"; then
            rm -f ~/.dashcore/dash.conf.dascore-utils-bak
        fi
    fi

    export PATH="$HOME/.local/opt/dashcore/bin:$PATH"
    if ! command -v dashd > /dev/null ||
        ! command -v dash-qt > /dev/null; then
        "$HOME/.local/bin/webi" dashcore
    fi

    # Always try to correct the permissions due to
    # https://github.com/dashpay/dash/issues/5420
    chmod -R og-rwx "${HOME}/.dashcore/" || true
}

__install_dashcore_utils
