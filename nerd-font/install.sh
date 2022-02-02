#!/bin/bash
set -e
set -u

function __redirect_alias_nerdfont() {
    echo "'nerd-font' is an alias for 'nerdfont'"
    WEBI_HOST=${WEBI_HOST:-"https://webinstall.dev"}
    curl -fsSL "$WEBI_HOST/nerdfont@${WEBI_VERSION:-}" | bash
}

__redirect_alias_nerdfont
