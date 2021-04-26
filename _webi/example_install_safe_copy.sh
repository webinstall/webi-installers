# For installing from the extracted package tmp directory
pkg_install() {
    pushd "$WEBI_TMP" 2>&1 > /dev/null

    if [ -n "$(command -v rsync 2> /dev/null | grep rsync)" ]; then
        rsync -Krl ./xmpl*/ "$pkg_src/" 2> /dev/null
    else
        cp -Hr ./xmpl*/* "$pkg_src/" 2> /dev/null
        cp -Hr ./xmpl*/.* "$pkg_src/" 2> /dev/null
    fi
    rm -rf ./xmpl*

    popd 2>&1 > /dev/null
}
