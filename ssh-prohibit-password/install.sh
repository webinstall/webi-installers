#!/bin/sh
set -e
set -u

# shellcheck disable=SC2016

__alias_sshd_prohibit_password() {
    echo "'ssh-prohibit-password@${WEBI_TAG:-stable}' is an alias for 'sshd-prohibit-password@${WEBI_VERSION-}'"
    WEBI_HOST=${WEBI_HOST:-"https://webinstall.dev"}
    curl -fsSL "$WEBI_HOST/sshd-prohibit-password@${WEBI_VERSION-}" | sh
}

__alias_sshd_prohibit_password
