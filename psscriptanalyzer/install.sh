#!/bin/sh
set -e
set -u

__install_psscriptanalyzer() {
    echo "Checking for pwsh (PowerShell Core)..."
    if ! command -v pwsh > /dev/null; then
        "$HOME/.local/bin/webi" pwsh
        export PATH="$HOME/.local/opt/pwsh:$PATH"
        pwsh -V
    fi

    pwsh -Command "Install-Module -Name PSScriptAnalyzer -Scope CurrentUser -AllowClobber"
    pwsh -Command 'Get-InstalledModule -Name PSScriptAnalyzer | Select-Object -Property "Name", "Version" | Format-List'
}

__install_psscriptanalyzer
