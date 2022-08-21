#!/bin/sh
set -e
set -u

__get_git_email() {
    git config --global user.email
    # grep 'email\s*=.*@' ~/.gitconfig | tr -d '\t ' | head -n 1 | cut -d'=' -f2
}

__get_pubkey_id() {
    gpg --list-secret-keys --keyid-format LONG |
        grep sec |
        cut -d'/' -f2 |
        cut -d' ' -f1
}

__shadow_read() {
    # See https://stackoverflow.com/a/38557313
    stty -echo
    IFS= read -r MY_REPLY
    stty echo
    echo "$MY_REPLY"
}

_create_gpg_key() {
    if [ ! -e ~/.gitconfig ]; then
        return 1
    fi

    #grep 'name\s*=' ~/.gitconfig | head -n 1 | cut -d'=' -f2 | sed -e 's/^[\t ]*//'
    MY_NAME="$(git config --global user.name)"
    if [ -z "${MY_NAME}" ]; then
        return 1
    fi

    MY_EMAIL="$(
        __get_git_email
    )"
    if [ -z "${MY_EMAIL}" ]; then
        return 1
    fi

    MY_HOST="$(hostname)"

    # Without passphrase:
    #gpg --batch --generate-key --pinentry=loopback --passphrase=''

    # With passphrase via macOS Keychain
    gpg_opts="
     %echo Generating RSA 3072 key...
     %echo Warning: It may take several minutes to gather enough entropy,
     %echo          especially on a linux VPS if haveged isn't installed.
     %echo          (try moving the mouse, downloading large files, etc)
     Key-Type: RSA
     Key-Length: 3072
     Subkey-Type: RSA
     Subkey-Length: 3072
     Name-Real: ${MY_NAME}
     Name-Comment: ${MY_HOST}
     Name-Email: ${MY_EMAIL}
     Expire-Date: 0
     %commit
    "
    if ! echo "$gpg_opts" | gpg --batch --generate-key 2> /dev/null; then
        echo >&2 ""
        echo >&2 ""
        echo >&2 ""
        echo >&2 "== STOP! CHOOSE A PASSPHRASE =="
        echo >&2 ""
        echo >&2 "Choose a passphrase for this GPG Key."
        echo >&2 "(the passphrase will not be shown as you type)"
        echo >&2 ""
        printf >&2 "Passphrase: "
        MY_REPLY="$(__shadow_read)"
        echo >&2 ""
        echo "
         %echo Generating RSA 3072 key...
         %echo Warning: It may take several minutes to gather enough entropy,
         %echo          especially on a linux VPS if haveged isn't installed.
         %echo          (try moving the mouse, downloading large files, etc)
         Key-Type: RSA
         Key-Length: 3072
         Subkey-Type: RSA
         Subkey-Length: 3072
         Name-Real: ${MY_NAME}
         Name-Comment: ${MY_HOST}
         Name-Email: ${MY_EMAIL}
         Passphrase: ${MY_REPLY}
         Expire-Date: 0
         %commit
        " | gpg --batch --generate-key
    fi
    echo >&2 "Done"
}

# (maybe) Create first key
if ! gpg --list-secret-keys | grep -q sec; then
    if ! _create_gpg_key; then
        echo >&2 ""
        echo >&2 "Please set your name and email, and then try again:"
        echo >&2 ""
        echo >&2 "    git config --global user.name 'John Doe'"
        echo >&2 "    git config --global user.email johndoe@example.com"
        echo >&2 "    gpg-pubkey"
        echo >&2 ""
        echo >&2 "(or manually create a private key first)"
        echo >&2 ""
        exit 1
    fi
fi

MY_KEY_ID="$(
    __get_pubkey_id
)"

MY_EMAIL="$(
    __get_git_email
)"

#gpg --send-keys "${MY_KEY_ID}"

MY_ASC_RELPATH="Downloads/${MY_EMAIL}.${MY_KEY_ID}.gpg.asc"
mkdir -p ~/Downloads/
rm -f ~/"${MY_ASC_RELPATH}"
gpg --armor --export "${MY_KEY_ID}" > ~/"${MY_ASC_RELPATH}"

echo >&2 ""
echo >&2 "GnuPG Public Key ID: ${MY_KEY_ID}"
echo >&2 ""
#shellcheck disable=SC2088
echo >&2 "~/${MY_ASC_RELPATH}":
echo >&2 ""
cat ~/"${MY_ASC_RELPATH}"
echo >&2 ""
