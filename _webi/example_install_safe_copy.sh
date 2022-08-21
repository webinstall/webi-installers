#!/bin/sh
set -e
set -u

# For installing from the extracted package tmp directory
pkg_install() {
    (
        cd "$WEBI_TMP"

        if command -v rsync 2> /dev/null | grep -q rsync; then
            rsync -Krl ./xmpl*/ "$pkg_src/" 2> /dev/null
        else
            cp -Hr ./xmpl*/* "$pkg_src/" 2> /dev/null
            cp -Hr ./xmpl*/.* "$pkg_src/" 2> /dev/null
        fi
        rm -rf ./xmpl*

    )
}
