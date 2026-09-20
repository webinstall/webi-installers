#!/bin/sh
# shellcheck disable=SC1012
# Download and list representative release archives without running them.

set -eu

usage() {
    printf 'usage: %s [-o OUTPUT_DIR] PACKAGE OWNER/REPO VERSION [VERSION ...]\n' "$0" >&2
}

output_dir=${TMPDIR:-/tmp}/webi-review-assets
while test "$#" -gt 0; do
    case "$1" in
        -h|--help)
            usage
            exit 0
            ;;
        -o|--output-dir)
            test "$#" -ge 2 || {
                printf '%s\n' "error: $1 needs a directory" >&2
                usage
                exit 2
            }
            output_dir=$2
            shift 2
            ;;
        --)
            shift
            break
            ;;
        -*)
            printf '%s\n' "error: unknown option: $1" >&2
            usage
            exit 2
            ;;
        *)
            break
            ;;
    esac
done

if test "$#" -lt 3; then
    usage
    exit 2
fi

package=$1
repo=$2
shift 2
mkdir -p "$output_dir"
output_dir=$(cd "$output_dir" && pwd)

case "$repo" in
    *[!A-Za-z0-9_./-]*)
        printf 'error: invalid OWNER/REPO\n' >&2
        exit 2
        ;;
esac

curl_api() {
    url=$1
    if test -n "${GITHUB_TOKEN:-}"; then
        curl -fsSL -H 'Accept: application/vnd.github+json' \
            -H "Authorization: Bearer ${GITHUB_TOKEN}" "$url"
    else
        curl -fsSL -H 'Accept: application/vnd.github+json' "$url"
    fi
}

for version in "$@"; do
    case "$version" in
        v*) tag=$version ;;
        *) tag="v$version" ;;
    esac

    printf '%s\n' "## $repo $tag"
    release_json=$(curl_api "https://api.github.com/repos/$repo/releases/tags/$tag")
    tab=$(printf '\t')
    printf '%s\n' "$release_json" | jq -r --arg package "$package" '.assets[] | select(.name | test("^" + $package + "-[^-]+-(linux|osx)-(x64|arm64)\\.tar\\.gz$|^" + $package + "-[^-]+-win-(x64|arm64)\\.zip$")) | [.name, .browser_download_url] | @tsv' |
        while IFS="$tab" read -r name url; do
            test -n "$name"
            curl -fsSL "$url" -o "$output_dir/$name"
            printf '%s\n' "$name"
        done
done

if command -v container > /dev/null 2>&1; then
    container system start > /dev/null
else
    printf '%s\n' 'error: Apple Container CLI is required' >&2
    exit 1
fi

printf '%s\n' '--- tar.gz contents (Ubuntu 24.04) ---'
# shellcheck disable=SC2016
container run --rm --read-only --cap-drop ALL \
    --uid "$(id -u)" --gid "$(id -g)" \
    --mount "type=bind,source=$output_dir,target=/assets,readonly" \
    ubuntu:24.04 sh -c '
set -eu
for archive in /assets/*.tar.gz; do
    echo "--- $(basename "$archive") ---"
    tar -tzf "$archive"
done
'

printf '%s\n' '--- zip contents (Alpine) ---'
# shellcheck disable=SC2016
container run --rm --read-only --cap-drop ALL \
    --uid "$(id -u)" --gid "$(id -g)" \
    --mount "type=bind,source=$output_dir,target=/assets,readonly" \
    alpine:3.22 sh -c '
set -eu
for archive in /assets/*.zip; do
    echo "--- $(basename "$archive") ---"
    unzip -l "$archive"
done
'

sh "$(dirname "$0")/part4-evaluate.sh" "$package" "$output_dir"
printf '%s\n' "assets saved in $output_dir"
