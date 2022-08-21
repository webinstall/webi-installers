#!/bin/sh
set -e
set -u

__git_gpg_init() {
    export PATH="$HOME/.local/opt/gnupg/bin:$PATH"
    export PATH="$HOME/.local/opt/gnupg/bin/pinentry-mac.app/Contents/MacOS:$PATH"

    # TODO check for public key without gpg-pubkey?
    if ! command -v gpg-pubkey; then
        "$HOME/.local/bin/webi" gpg-pubkey
    else
        gpg-pubkey
    fi

    MY_KEY_ID="$(
        gpg-pubkey-id
    )"

    printf "Enabling automatic git commit signing...
	    git config --global user.signingkey %s
	    git config --global commit.gpgsign true
	    git config --global log.showSignature true
	" "${MY_KEY_ID}"

    git config --global user.signingkey "${MY_KEY_ID}"
    git config --global commit.gpgsign true
    git config --global log.showSignature true

    echo ""
    echo "Successfully updated ~/.gitconfig"
    echo ""
    echo "How to verify signed commits on GitHub:"
    echo ""
    echo "    1. Go to 'Add GPG Key': https://github.com/settings/gpg/new"
    echo "    2. Copy and paste the key above from the first ---- to the last ----"
    echo ""
}

__git_gpg_init
