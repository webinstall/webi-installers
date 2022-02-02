#!/bin/bash

#set -x

function __install_webi() {

    #WEBI_PKG=
    #WEBI_HOST=https://webinstall.dev
    export WEBI_HOST

    echo ""
    printf "Thanks for using webi to install '\e[32m${WEBI_PKG:-}\e[0m' on '\e[31m$(uname -s)/$(uname -m)\e[0m'.\n"
    echo "Have a problem? Experience a bug? Please let us know:"
    echo "        https://github.com/webinstall/webi-installers/issues"
    echo ""
    printf "\e[31mLovin'\e[0m it? Say thanks with a \e[34mStar on GitHub\e[0m:\n"
    printf "        \e[32mhttps://github.com/webinstall/webi-installers\e[0m\n"
    echo ""

    WEBI_WELCOME=true
    export WEBI_WELCOME

    set -e
    set -u

    mkdir -p "$HOME/.local/bin"

    cat << EOF > "$HOME/.local/bin/webi"
#!/bin/bash

set -e
set -u
#set -x

function __webi_main () {

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


    function webinstall() {

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
                    echo "You can either"
                    echo "A) can CLOSE and REOPEN Terminal or"
                    echo "B) RUN these exports:"
                    echo ""
                    echo "\$my_paths"
                    echo ""
                fi
                rm -f "\$_webi_tmp/.PATH.env"
            fi
        fi

    }

    usage() {

        ## show help if no params given or help flags are used
        if [ \$# -eq 0 ] || [[ "\$1" =~ ^(-h|--help)$ ]]; then
            printf "\e[31mwebi\e[32m v1.x\e[0m Copyright 2020+ AJ ONeal\n"
            printf "    \e[34mhttps://webinstall.dev/webi\e[0m\n"
            echo ""
            echo "Webi is the best way to install the modern developer tools you love."
            echo "It's fast, easy-to-remember, and conflict free."
            echo ""
            echo "Usage:"
            echo ""
            echo "To install things:"
            echo "    webi <thing1>[@version] [thing2] ..."
            echo ""
            echo "To uninstall things:"
            echo "    rm -rf ~/.local/opt/<thing1>"
            echo "(see, for example, https://webinstall.dev/<thing1> for any special notes on uninstalling)"
            echo ""
            echo "FAQ:"
            printf "    See \e[34mhttps://webinstall.dev/faq\e[0m\n"
            echo ""
            echo "And always remember:"
            echo "    Friends don't let friends use brew for simple, modern tools that don't need it."
            exit 0
        fi

    }

    usage "\$@"

    for pkgname in "\$@"
    do
        webinstall "\$pkgname"
    done

    show_path_updates

}

__webi_main "\$@"

EOF

    chmod a+x "$HOME/.local/bin/webi"

    if [ -n "${WEBI_PKG:-}" ]; then
        "$HOME/.local/bin/webi" "${WEBI_PKG}"
    else
        echo ""
        echo "Hmm... no WEBI_PKG was specified. This is probably an error in the script."
        echo ""
        echo "Please open an issue with this information: Package '${WEBI_PKG:-}' on '$(uname -s)/$(uname -m)'"
        echo "    https://github.com/webinstall/packages/issues"
        echo ""
    fi

}

__install_webi
