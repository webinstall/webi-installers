#!/bin/sh
# Run repeatable Part 2 checks for a checked-out installer commit.

set -eu

if test "$#" -ne 3; then
    printf '%s\n' "usage: $0 COMMIT PACKAGE UPSTREAM_OWNER/REPO" >&2
    exit 2
fi

commit=$1
package=$2
upstream=$3
raw="https://raw.githubusercontent.com/webinstall/webi-installers/$commit/$package"
tmp_dir=$(mktemp -d "${TMPDIR:-/tmp}/webi-part2.XXXXXXXX")
trap 'rm -rf "$tmp_dir"' EXIT HUP INT TERM

printf '%s\n' '== installer checks =='
sh "$(dirname "$0")/installer-checks.sh" "$raw" "$package"

printf '%s\n' '== git diff check =='
git diff --check "$commit^" "$commit"

printf '%s\n' '== changed-file command scan =='
git diff --unified=0 "$commit^" "$commit" -- \
    "$package/install.sh" "$package/install.ps1" "$package/releases.conf" |
    grep -Ein 'upload|secret|token|base64|eval|curl.*-X[[:space:]]*POST|wget.*--post|Invoke-WebRequest.*-Method[[:space:]]*Post|nc[[:space:]]|rm[[:space:]]+-rf' ||
    printf '%s\n' 'no suspicious command patterns (expected downloads excluded)'

printf '%s\n' '== upstream latest release =='
curl -fsSL "https://api.github.com/repos/$upstream/releases?per_page=1" |
    jq -r '.[0] | "tag=\(.tag_name // "none") published=\(.published_at // "none")", (.assets[]?.name // empty)' |
    { head -n 40; echo '...'; tail -n 10; }

printf '%s\n' '== local commit files =='
git diff --name-status "$commit^" "$commit" -- "$package" test/install.sh
