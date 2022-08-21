#!/bin/sh
set -e
set -u

__init_jshint() {
    OLD_PATH="${PATH}"
    PATH="${HOME}/.local/opt/node/bin:${PATH}"
    if [ -z "$(npm --version 2> /dev/null)" ]; then
        export PATH="${OLD_PATH}"
        "$HOME/.local/bin/webi" node
        export PATH="${HOME}/.local/opt/node/bin:${PATH}"
    fi
    npm install -g jshint@latest

    curl -fsS \
        -o ~/.jshintrc.defaults.json5 \
        'https://raw.githubusercontent.com/jshint/jshint/master/examples/.jshintrc' || true

    curl -fsS \
        -o ~/.jshintrc.webi.json5 \
        "${WEBI_HOST}/packages/jshint/jshintrc.webi.json5" || true
}

__init_jshint
