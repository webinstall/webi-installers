#!/bin/bash
# title: Python 3 (alias for python)
# homepage: https://webinstall.dev/python
# tagline: Alias for https://webinstall.dev/python
# alias: python
# description: |
#   See https://webinstall.dev/python

set -e
set -u

function __redirect_alias_python() {
    echo "'python@${WEBI_TAG:-stable}' is an alias for 'python@${WEBI_VERSION:-}'"
    WEBI_HOST=${WEBI_HOST:-"https://webinstall.dev"}
    curl -fsSL "$WEBI_HOST/python@${WEBI_VERSION:-}" | bash
}

__redirect_alias_python
