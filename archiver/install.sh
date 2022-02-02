#!/bin/bash
set -e
set -u

function __redirect_alias_arc() {
    echo "'archiver@${WEBI_TAG:-stable}' is an alias for 'arc@${WEBI_VERSION:-}'"
    WEBI_HOST=${WEBI_HOST:-"https://webinstall.dev"}
    curl -fsSL "$WEBI_HOST/arc@${WEBI_VERSION:-}" | bash
}

__redirect_alias_arc
