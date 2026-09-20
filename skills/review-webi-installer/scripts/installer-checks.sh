#!/bin/sh
# Run the repository's non-mutating checks against one Webi installer.

set -eu

if test "$#" -ne 2; then
    printf 'usage: %s RAW_PACKAGE_URL PACKAGE_DIR\n' "$0" >&2
    printf 'example: %s https://raw.githubusercontent.com/webinstall/webi-installers/COMMIT/ndx ndx\n' "$0" >&2
    exit 2
fi

raw_package_url=$1
package_dir=$2
tmp_dir=$(mktemp -d "${TMPDIR:-/tmp}/webi-installer-checks.XXXXXXXX")
trap 'rm -rf "$tmp_dir"' EXIT HUP INT TERM

fetch_file() {
    name=$1
    curl -fsSL "$raw_package_url/$name" > "$tmp_dir/$name"
}

fetch_file install.sh
fetch_file install.ps1
fetch_file README.md

sh -n "$tmp_dir/install.sh"
shellcheck -s sh -S style --exclude=SC2154,SC2034 "$tmp_dir/install.sh"
shfmt -d -i 4 -sr -ci -s "$tmp_dir/install.sh"

if command -v prettier > /dev/null 2>&1; then
    prettier --check "$tmp_dir/README.md"
fi

if command -v pwsh > /dev/null 2>&1; then
    # shellcheck disable=SC2016
    PSFILE="$tmp_dir/install.ps1" pwsh -NoProfile -NonInteractive -Command '
$tokens = $null
$errors = $null
[System.Management.Automation.Language.Parser]::ParseFile($Env:PSFILE, [ref]$tokens, [ref]$errors) > $null
if ($errors.Count) {
    $errors | ForEach-Object Message
    exit 1
}
'
else
    printf '%s\n' 'warning: pwsh not found; skipped PowerShell parse' >&2
fi

printf '%s\n' "installer checks passed: $package_dir"
