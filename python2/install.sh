#!/bin/bash

set -e
set -u

function __init_python2() {
    if [[ ! -x "${HOME}/.pyenv/bin/pyenv" ]]; then
        "${HOME}/.local/bin/webi" "pyenv"
    fi
    export PATH="${HOME}/.pyenv/bin:${PATH}"
    export PATH="${HOME}/.pyenv/shims:${PATH}"

    #eval "$(pyenv init -)"
    #eval "$(pyenv virtualenv-init -)"

    pyenv update

    my_latest_python2="$(
        pyenv install --list |
            grep -v -- - |
            grep '2\.[0-9]\+\.[0-9]\+$' |
            tail -n 1 |
            cut -d' ' -f3
    )"

    #my_python="${WEBI_VERSION:-${my_latest_python2}}"
    my_python="${my_latest_python2}"
    echo "Installing ${my_python}"
    pyenv install -v "${my_python}"
    pyenv global "${my_python}"

    echo ''
    echo 'NOTE: You may also need to CLOSE and RE-OPEN your terminal for pyenv to take effect.'
    echo '(to switch versions of python, see https://webinstall.dev/pyenv)'
    echo ''
}

__init_python2
