#!/bin/sh
set -e
set -u

__install_gpg_pubkey() {
    MY_CMD="gpg-pubkey"

    rm -f "$HOME/.local/bin/$MY_CMD"
    webi_download "$WEBI_HOST/packages/$MY_CMD/$MY_CMD.sh" "$HOME/.local/bin/$MY_CMD"
    chmod a+x "$HOME/.local/bin/$MY_CMD"
}

__install_gpg_pubkey_id() {
    MY_CMD="gpg-pubkey"
    MY_SUBCMD="gpg-pubkey-id"

    rm -f "$HOME/.local/bin/$MY_SUBCMD"
    webi_download "$WEBI_HOST/packages/$MY_CMD/$MY_SUBCMD.sh" "$HOME/.local/bin/$MY_SUBCMD"
    chmod a+x "$HOME/.local/bin/$MY_SUBCMD"
}

__check_gpg_exists() {
    if ! command -v gpg; then
        "$HOME/.local/bin/webi" gpg
        export PATH="$HOME/.local/opt/gnupg/bin:$PATH"
        export PATH="$HOME/.local/opt/gnupg/bin/pinentry-mac.app/Contents/MacOS:$PATH"
    fi
}

__install_gpg_pubkey_id
__install_gpg_pubkey
__check_gpg_exists

# run the command
"$HOME/.local/bin/$MY_CMD"
