#!/bin/sh
set -e
set -u

__run_go_essentials() {
    if ! command -v go 2> /dev/null; then
        "$HOME/.local/bin/webi" "go@${WEBI_TAG}"
    fi

    export PATH="$HOME/.local/opt/go/bin:$PATH"

    my_install="install"
    # go1.16 is the min version for proper 'go install'
    my_version="$(
        go version | cut -d' ' -f3
    )"
    my_major="$(
        echo "${my_version}" | cut -d'.' -f1 || echo '0'
    )"
    my_minor="$(
        echo "${my_version}" | cut -d'.' -f2 || echo '0'
    )"

    my_install="get"
    if [ "${my_major}" = "go1" ]; then
        if [ "${my_minor}" -ge 16 ]; then
            my_install="install"
        fi
    elif [ "${my_major}" = "go2" ]; then
        my_install="install"
    fi

    # Install x go
    echo "Building go language tools..."
    export GO111MODULE=on

    # See https://pkg.go.dev/mod/golang.org/x/tools?tab=packages

    echo ""
    echo godoc
    go "${my_install}" golang.org/x/tools/cmd/godoc@latest > /dev/null #2>/dev/null

    echo ""
    echo gopls
    go "${my_install}" golang.org/x/tools/gopls@latest > /dev/null #2>/dev/null

    echo ""
    echo guru
    go "${my_install}" golang.org/x/tools/cmd/guru@latest > /dev/null #2>/dev/null

    echo ""
    echo golint
    go "${my_install}" golang.org/x/lint/golint@latest > /dev/null #2>/dev/null

    echo ""
    echo goimports
    go "${my_install}" golang.org/x/tools/cmd/goimports@latest > /dev/null #2>/dev/null

    echo ""
    echo gomvpkg
    go "${my_install}" golang.org/x/tools/cmd/gomvpkg@latest > /dev/null #2>/dev/null

    echo ""
    echo gorename
    go "${my_install}" golang.org/x/tools/cmd/gorename@latest > /dev/null #2>/dev/null

    echo ""
    echo gotype
    go "${my_install}" golang.org/x/tools/cmd/gotype@latest > /dev/null #2>/dev/null

    echo ""
    echo stringer
    go "${my_install}" golang.org/x/tools/cmd/stringer@latest > /dev/null #2>/dev/null

    echo ""
    # literal $HOME on purpose
    # shellcheck disable=SC2016
    echo 'Installed go "x" tools to GOBIN=$HOME/go/bin'

    printf '\n'
    printf 'Suggestion: Also check out these great productivity multipliers:\n'
    printf '\n'
    printf '    - vim-essentials  (sensible defaults for vim)\n'
    printf '    - vim-go          (golang linting, etc)\n'
    printf '\n'
}

__run_go_essentials
