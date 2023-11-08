#!/bin/sh
set -e
set -u

__run_pwsh_essentials() {
    # PowerShell Core
    if ! command -v pwsh > /dev/null; then
        "$HOME/.local/bin/webi" "pwsh@${WEBI_TAG}"
    fi
    export PATH="$HOME/.local/opt/pwsh:$PATH"

    # PSScriptAnalyzer (Linter, Fixer, & Formatter)
    "$HOME/.local/bin/webi" "psscriptanalyzer"

    # pwsh-fmt, pwsh-fix, pwsh-lint
    for b_file in pwsh-fmt.ps1 pwsh-fix.ps1 pwsh-lint.ps1; do
        rm -f ~/.local/bin/"${b_file}"
        webi_download \
            "${WEBI_HOST}/packages/${PKG_NAME}/${b_file}" \
            ~/.local/bin/"${b_file}" \
            "${b_file}"
        chmod a+x ~/.local/bin/"${b_file}"
        ~/.local/bin/"${b_file}" ~/.local/bin/"${b_file}"
    done
    echo ""
}

__run_pwsh_essentials
