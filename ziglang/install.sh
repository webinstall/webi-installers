#!/bin/bash
set -e
set -u

function __redirect_alias_zig() {
    echo "'ziglang@${WEBI_TAG:-stable}' is an alias for 'zig@${WEBI_VERSION:-}'"
    WEBI_HOST=${WEBI_HOST:-"https://webinstall.dev"}
    curl -fsSL "$WEBI_HOST/zig@${WEBI_VERSION:-}" | bash
}

__redirect_alias_zig
