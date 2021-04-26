#!/bin/bash

{

    set -e
    set -u

    #WEBI_PKG=
    #WEBI_HOST=https://webinstall.dev
    export WEBI_HOST

    mkdir -p "$HOME/.local/bin"

    cat << EOF > "$HOME/.local/bin/webi"
#!/bin/bash

set -e
set -u

{

export WEBI_TIMESTAMP=\$(date +%F_%H-%M-%S)
export _webi_tmp="\${_webi_tmp:-\$(mktemp -d -t webi-\$WEBI_TIMESTAMP.XXXXXXXX)}"

if [ -n "\${_WEBI_PARENT:-}" ]; then
  export _WEBI_CHILD=true
else
  export _WEBI_CHILD=
fi
export _WEBI_PARENT=true

##
## Detect acceptable package formats
##

my_ext=""
set +e
# NOTE: the order here is least favorable to most favorable
if [ -n "\$(command -v pkgutil)" ]; then
    my_ext="pkg,\$my_ext"
fi
# disable this check for the sake of building the macOS installer on Linux
#if [ -n "\$(command -v diskutil)" ]; then
    # note: could also detect via hdiutil
    my_ext="dmg,\$my_ext"
#fi
if [ -n "\$(command -v git)" ]; then
    my_ext="git,\$my_ext"
fi
if [ -n "\$(command -v unxz)" ]; then
    my_ext="xz,\$my_ext"
fi
if [ -n "\$(command -v unzip)" ]; then
    my_ext="zip,\$my_ext"
fi
# for mac/linux 'exe' refers to the uncompressed binary without extension
my_ext="exe,\$my_ext"
if [ -n "\$(command -v tar)" ]; then
    my_ext="tar,\$my_ext"
fi
my_ext="\$(echo "\$my_ext" | sed 's/,$//')" # nix trailing comma
set -e


##
## Detect http client
##

set +e
export WEBI_CURL="\$(command -v curl)"
export WEBI_WGET="\$(command -v wget)"
set -e

export WEBI_HOST="\${WEBI_HOST:-https://webinstall.dev}"
export WEBI_UA="\$(uname -a)"


webinstall() {

    my_package="\${1:-}"
    if [ -z "\$my_package" ]; then
        >&2 echo "Usage: webi <package>@<version> ..."
        >&2 echo "Example: webi node@lts rg"
        exit 1
    fi

    export WEBI_BOOT="\$(mktemp -d -t "\$my_package-bootstrap.\$WEBI_TIMESTAMP.XXXXXXXX")"

    my_installer_url="\$WEBI_HOST/api/installers/\$my_package.sh?formats=\$my_ext"
    set +e
    if [ -n "\$WEBI_CURL" ]; then
        curl -fsSL "\$my_installer_url" -H "User-Agent: curl \$WEBI_UA" \\
            -o "\$WEBI_BOOT/\$my_package-bootstrap.sh"
    else
        wget -q "\$my_installer_url" --user-agent="wget \$WEBI_UA" \\
            -O "\$WEBI_BOOT/\$my_package-bootstrap.sh"
    fi
    if ! [ \$? -eq 0 ]; then
      >&2 echo "error fetching '\$my_installer_url'"
      exit 1
    fi
    set -e

    pushd "\$WEBI_BOOT" 2>&1 > /dev/null
        bash "\$my_package-bootstrap.sh"
    popd 2>&1 > /dev/null

    rm -rf "\$WEBI_BOOT"

}

show_path_updates() {

    if ! [ -n "\${_WEBI_CHILD}" ]; then
        if [ -f "\$_webi_tmp/.PATH.env" ]; then
            my_paths=\$(cat "\$_webi_tmp/.PATH.env" | sort -u)
            if [ -n "\$my_paths" ]; then
                echo "IMPORTANT: You must update you PATH to use the installed program(s)"
                echo ""
                echo "You can CLOSE and REOPEN Terminal, or RUN these exports:"
                echo ""
                echo "\$my_paths"
                echo ""
            fi
            rm -f "\$_webi_tmp/.PATH.env"
        fi
    fi

}

for pkgname in "\$@"
do
    webinstall "\$pkgname"
done

show_path_updates

}

EOF

    chmod a+x "$HOME/.local/bin/webi"

    if [ -n "${WEBI_PKG:-}" ]; then
        "$HOME/.local/bin/webi" "${WEBI_PKG}"
    fi

}
