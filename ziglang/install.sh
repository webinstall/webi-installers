#!/bin/sh
set -e
set -u

__redirect_alias_zig() {
    echo "'ziglang@${WEBI_TAG:-stable}' is an alias for 'zig@${WEBI_VERSION-}'"
    WEBI_HOST=${WEBI_HOST:-"https://webinstall.dev"}
    curl -fsSL "$WEBI_HOST/zig@${WEBI_VERSION-}" | sh
}

__redirect_alias_zig
