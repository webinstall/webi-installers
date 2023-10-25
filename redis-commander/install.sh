#!/bin/sh
set -e
set -u

__init_redis_commander() {
    if test -z "$(npm --version 2> /dev/null)"; then
        ~/.local/bin/webi node
        export PATH="$HOME/.local/opt/node/bin:$PATH"
    fi

    # In recent versions of node (~v18+), npm:
    #   - requires '--location=global' rather than '-g'
    #   - will modify 'package.json' when it shouldn't
    my_tmpdir="$(mktemp -d -t "webi-npm-tmp.XXXXXXXXXX")"
    (
        cd "${my_tmpdir}" || exit 1
        npm install --location=global redis-commander@latest
    )
}

__init_redis_commander
