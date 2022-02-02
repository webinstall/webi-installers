#!/bin/bash
set -e
set -u

function __init_prettier() {
    if [ -z "$(npm --version 2> /dev/null)" ]; then
        webi node
        export PATH="$HOME/.local/opt/node/bin:$PATH"
    fi
    npm install -g prettier@latest
}

__init_prettier
