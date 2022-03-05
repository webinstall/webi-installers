#!/bin/bash
set -e
set -u

function __redirect_alias_dashcore() {
    echo "'dash-cli@${WEBI_TAG:-}' (project) is an alias for 'dashcore@${WEBI_VERSION:-}' (command)"
    WEBI_HOST=${WEBI_HOST:-"https://webinstall.dev"}
    curl -fsSL "$WEBI_HOST/dashcore@${WEBI_VERSION:-}" | bash
}

__redirect_alias_dashcore
