#!/bin/bash
set -e
set -u

__redirect_alias_golang() {
    echo "'go@${WEBI_TAG:-stable}' is an alias for 'golang@${WEBI_VERSION:-}'"
    WEBI_HOST=${WEBI_HOST:-"https://webinstall.dev"}
    curl -fsSL "$WEBI_HOST/golang@${WEBI_VERSION:-}" | bash
}

__redirect_alias_golang
