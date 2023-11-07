#!/bin/sh
set -e
set -x

__install_psscriptanalyzer() {
    echo "Checking for pwsh (PowerShell Core)..."
    if ! command -v pwsh > /dev/null; then
        "$HOME/.local/bin/webi" pwsh
        export PATH="$HOME/.local/opt/pwsh:$PATH"
    fi

    pwsh -Command "Install-Module -Name PSScriptAnalyzer -Scope CurrentUser -AllowClobber"
}

__install_psscriptanalyzer
