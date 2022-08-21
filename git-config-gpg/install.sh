#!/bin/sh
set -e
set -u

__install_git_gpg_init() {
    MY_CMD="git-config-gpg"

    rm -f "$HOME/.local/bin/$MY_CMD"
    webi_download "$WEBI_HOST/packages/$MY_CMD/$MY_CMD.sh" "$HOME/.local/bin/$MY_CMD"
    chmod a+x "$HOME/.local/bin/$MY_CMD"
}

__check_gpg_pubkey_exists() {
    if ! command -v gpg; then
        "$HOME/.local/bin/webi" gpg-pubkey
        export PATH="$HOME/.local/opt/gnupg/bin:$PATH"
        export PATH="$HOME/.local/opt/gnupg/bin/pinentry-mac.app/Contents/MacOS:$PATH"
    fi
}

__check_gpg_exists() {
    if ! command -v gpg; then
        "$HOME/.local/bin/webi" gpg
        export PATH="$HOME/.local/opt/gnupg/bin:$PATH"
        export PATH="$HOME/.local/opt/gnupg/bin/pinentry-mac.app/Contents/MacOS:$PATH"
    fi
}

__install_git_gpg_init
__check_gpg_pubkey_exists
__check_gpg_exists

# run the command
"$HOME/.local/bin/$MY_CMD"
