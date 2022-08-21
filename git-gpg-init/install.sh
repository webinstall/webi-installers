#!/bin/sh
set -e
set -u

__redirect_alias_git_config_gpg() {
    echo "'git-gpg-init' is a deprecated alias for 'git-config-gpg'"
    WEBI_HOST=${WEBI_HOST:-"https://webinstall.dev"}
    curl -fsSL "$WEBI_HOST/git-config-gpg" | sh
}

__redirect_alias_git_config_gpg
