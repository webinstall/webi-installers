#!/bin/sh
set -e
set -u

__init_redis_commander() {
    if [ -z "$(npm --version 2> /dev/null)" ]; then
        "$HOME/.local/bin/webi" node
        export PATH="$HOME/.local/opt/node/bin:$PATH"
    fi
    npm install -g redis-commander@latest
}

__init_redis_commander
