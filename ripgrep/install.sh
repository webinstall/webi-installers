#!/bin/bash
# title: Ripgrep (alias)
# homepage: https://webinstall.dev/rg
# tagline: `ripgrep` (project) is an alias for `rg` (command)
# alias: rg
# description: |
#   See https://webinstall.dev/rg

function __redirect_alias_rg() {
    echo "'ripgrep@${WEBI_TAG:-}' (project) is an alias for 'rg@${WEBI_VERSION:-}' (command)"
    WEBI_HOST=${WEBI_HOST:-"https://webinstall.dev"}
    curl -fsSL "$WEBI_HOST/rg@${WEBI_VERSION:-}" | bash
}

__redirect_alias_rg
