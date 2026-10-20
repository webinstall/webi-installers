#!/bin/sh
# Gather repeatable evidence for the upstream-project review.

set -eu

if test "$#" -lt 1 || test "$#" -gt 2; then
    printf '%s\n' "usage: $0 OWNER/REPO [HISTORY_DEPTH]" >&2
    exit 2
fi

repo=$1
depth=${2:-100}
case "$depth" in
    ''|*[!0-9]*) printf '%s\n' 'error: HISTORY_DEPTH must be a positive integer' >&2; exit 2 ;;
esac
test "$depth" -gt 0 || { printf '%s\n' 'error: HISTORY_DEPTH must be greater than zero' >&2; exit 2; }
case "$repo" in
    */*) ;;
    *) printf '%s\n' 'error: expected OWNER/REPO' >&2; exit 2 ;;
esac

tmp_dir=$(mktemp -d "${TMPDIR:-/tmp}/webi-upstream-review.XXXXXXXX")
trap 'rm -rf "$tmp_dir"' EXIT HUP INT TERM

printf '%s\n' '== shallow checkout =='
git clone --quiet --depth "$depth" "https://github.com/$repo.git" "$tmp_dir/repo"
checkout=$tmp_dir/repo
printf 'commit: '; git -C "$checkout" rev-parse HEAD
printf 'branch: '; git -C "$checkout" branch --show-current

printf '%s\n' '== relevant files =='
find "$checkout" -type f \( \
    -path '*/src/*' -o -path '*/lib/*' -o -path '*/cmd/*' -o \
    -path '*/.github/workflows/*' -o -name 'README*' -o -name 'LICENSE*' -o \
    -name 'license*' -o -name '*.csproj' -o -name 'go.mod' -o -name 'package.json' \
\) -not -path '*/.git/*' -print | sed "s#^$checkout/##" | sort | { head -n 120; echo '...'; tail -n 20; }

printf '%s\n' '== suspicious behavior scan =='
rg -n -i 'credential|token|secret|password|browser|cookie|ssh|upload|Process\.Start|ShellExecute|Invoke-WebRequest|curl|wget|Environment\.GetEnvironmentVariable|SetEnvironmentVariable|CreateDirectory|WriteAll|chmod|sudo|eval|Assembly\.Load' \
    "$checkout/src" "$checkout/.github/workflows" "$checkout/install.sh" "$checkout/install.ps1" 2>/dev/null |
    { head -n 160; echo '...'; tail -n 30; } || true

printf '%s\n' '== dependency and workflow summary =='
rg -n '<PackageReference|require\(|"dependencies"|uses:|git_url|nuget.org|api.github.com' \
    "$checkout" --glob '!*.sln*' --glob '!*.lock.json' --glob '!*/.git/*' 2>/dev/null |
    { head -n 160; echo '...'; tail -n 30; } || true

printf '%s\n' '== latest release =='
curl -fsSL "https://api.github.com/repos/$repo/releases?per_page=1" |
    jq -r '.[0] | "tag=\(.tag_name // "none") author=\(.author.login // "unknown") published=\(.published_at // "none") prerelease=\(.prerelease)", (.assets[]?.name // empty)' |
    { head -n 40; echo '...'; tail -n 10; }
