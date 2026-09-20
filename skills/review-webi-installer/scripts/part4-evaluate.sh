#!/bin/sh
# Deterministically classify simple archive layouts inside disposable containers.

set -eu

if test "$#" -ne 2; then
    printf '%s\n' "usage: $0 PACKAGE ASSET_DIR" >&2
    exit 2
fi

package=$1
asset_dir=$2
case "$package" in
    ''|*[!A-Za-z0-9_-]*) printf '%s\n' 'error: invalid package name' >&2; exit 2 ;;
esac
test -d "$asset_dir" || { printf '%s\n' 'error: asset directory not found' >&2; exit 2; }
asset_dir=$(cd "$asset_dir" && pwd)

command -v container >/dev/null 2>&1 || {
    printf '%s\n' 'error: Apple Container CLI is required' >&2
    exit 1
}
container system start >/dev/null

printf '%s\n' '--- deterministic layout evaluation (Ubuntu 24.04) ---'
container run --rm --read-only --cap-drop ALL \
    --uid "$(id -u)" --gid "$(id -g)" \
    --mount "type=bind,source=$asset_dir,target=/assets,readonly" \
    ubuntu:24.04 sh -c '
set -eu
package=$1
for archive in /assets/*.tar.gz; do
    test -f "$archive" || continue
    entries=$(tar -tzf "$archive" | sort -u)
    if printf "%s\n" "$entries" | grep -Fqx "$package"; then
        category=idealist
    elif printf "%s\n" "$entries" | grep -Eq "/$package$"; then
        category=prestige
    else
        category=unknown-agent-review
    fi
    printf "%s: category=%s entries=%s\n" "$(basename "$archive")" "$category" "$(printf "%s\n" "$entries" | tr "\n" ",")"
done
' sh "$package"

printf '%s\n' '--- deterministic layout evaluation (Alpine 3.22) ---'
container run --rm --read-only --cap-drop ALL \
    --uid "$(id -u)" --gid "$(id -g)" \
    --mount "type=bind,source=$asset_dir,target=/assets,readonly" \
    alpine:3.22 sh -c '
set -eu
package=$1
for archive in /assets/*.zip; do
    test -f "$archive" || continue
    entries=$(unzip -l "$archive" | grep -E "^[[:space:]]*[0-9]+[[:space:]]" | tr -s " " | cut -d" " -f5- | sort -u)
    if printf "%s\n" "$entries" | grep -Fqx "$package.exe"; then
        category=idealist
    elif printf "%s\n" "$entries" | grep -Eq "/$package\.exe$"; then
        category=prestige
    else
        category=unknown-agent-review
    fi
    printf "%s: category=%s entries=%s\n" "$(basename "$archive")" "$category" "$(printf "%s\n" "$entries" | tr "\n" ",")"
done
' sh "$package"
