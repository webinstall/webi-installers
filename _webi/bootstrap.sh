#!/bin/sh
#<pre>

############################################################
# <h1>Cheat Sheet at CHEATSHEET_URL</h1>
# <meta http-equiv="refresh" content="3; URL='CHEATSHEET_URL'" />
############################################################

#set -x

__install_webi() {

    #WEBI_PKG=
    #WEBI_HOST=https://webinstall.dev
    export WEBI_HOST

    echo ""
    printf "Thanks for using webi to install '\e[32m%s\e[0m' on '\e[31m%s/%s\e[0m'.\n" "${WEBI_PKG-}" "$(uname -s)/$(uname -r)" "$(uname -m)"
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
#!/bin/sh

set -e
set -u
#set -x

__webi_main() {

    export WEBI_TIMESTAMP="\$(date +%F_%H-%M-%S)"
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

    my_libc=''
    if ldd /bin/ls 2> /dev/null | grep -q 'musl' 2> /dev/null; then
        my_libc=' musl-native'
    fi

    export WEBI_HOST="\${WEBI_HOST:-https://webinstall.dev}"
    export WEBI_UA="\$(uname -s)/\$(uname -r) \$(uname -m)/unknown\${my_libc}"


    webinstall() {

        my_package="\${1:-}"
        if [ -z "\$my_package" ]; then
            echo >&2 "Usage: webi <package>@<version> ..."
            echo >&2 "Example: webi node@lts rg"
            exit 1
        fi

        export WEBI_BOOT="\$(mktemp -d -t "\$my_package-bootstrap.\$WEBI_TIMESTAMP.XXXXXXXX")"

        my_installer_url="\$WEBI_HOST/api/installers/\$my_package.sh?formats=\$my_ext"
        if [ -n "\$WEBI_CURL" ]; then
            if !  curl -fsSL "\$my_installer_url" -H "User-Agent: curl \$WEBI_UA" \\
                -o "\$WEBI_BOOT/\$my_package-bootstrap.sh"; then
                echo >&2 "error fetching '\$my_installer_url'"
                exit 1
            fi
        else
            if !  wget -q "\$my_installer_url" --user-agent="wget \$WEBI_UA" \\
                -O "\$WEBI_BOOT/\$my_package-bootstrap.sh"; then
                echo >&2 "error fetching '\$my_installer_url'"
                exit 1
            fi
        fi

        (
            cd "\$WEBI_BOOT"
            sh "\$my_package-bootstrap.sh"
        )

        rm -rf "\$WEBI_BOOT"

    }

    show_path_updates() {

        if test -z "\${_WEBI_CHILD}"; then
            if test -f "\$_webi_tmp/.PATH.env"; then
                my_paths=\$(sort -u < "\$_webi_tmp/.PATH.env")
                if test -n "\$my_paths"; then
                    printf 'PATH.env updated with:\\n'
                    printf "%s\\n" "\$my_paths"
                    printf '\\n'
                    printf "\\e[31mTO FINISH\\e[0m: copy, paste & run the following command:\\n"
                    printf "\\n"
                    printf "        \\e[34msource ~/.config/envman/PATH.env\\e[0m\\n"
                    printf "        (newly opened terminal windows will update automatically)\\n"
                fi
                rm -f "\$_webi_tmp/.PATH.env"
            fi
        fi

    }

    version() {
        my_version=v1.1.15
        printf "\\e[31mwebi\\e[32m %s\\e[0m Copyright 2020+ AJ ONeal\\n" "\${my_version}"
        printf "    \\e[34mhttps://webinstall.dev/webi\\e[0m\\n"
    }

    # show help if no params given or help flags are used
    usage() {
        echo ""
        version
        echo ""

        printf "\\e[1mSUMMARY\\e[0m\\n"
        echo "    Webi is the best way to install the modern developer tools you love."
        echo "    It's fast, easy-to-remember, and conflict free."
        echo ""
        printf "\\e[1mUSAGE\\e[0m\\n"
        echo "    webi <thing1>[@version] [thing2] ..."
        echo ""
        printf "\\e[1mUNINSTALL\\e[0m\\n"
        echo "    Almost everything that is installed with webi is scoped to"
        echo "    ~/.local/opt/<thing1>, so you can remove it like so:"
        echo ""
        echo "    rm -rf ~/.local/opt/<thing1>"
        echo "    rm -f ~/.local/bin/<thing1>"
        echo ""
        echo "    Some packages have special uninstall instructions, check"
        echo "    https://webinstall.dev/<thing1> to be sure."
        echo ""
        printf "\\e[1mFAQ\\e[0m\\n"
        printf "    See \\e[34mhttps://webinstall.dev/faq\\e[0m\\n"
        echo ""
        printf "\\e[1mALWAYS REMEMBER\\e[0m\\n"
        echo "    Friends don't let friends use brew for simple, modern tools that don't need it."
        echo "    (and certainly not apt either **shudder**)"
        echo ""
    }

    if [ \$# -eq 0 ] || echo "\$1" | grep -q -E '^(-V|--version|version)$'; then
        version
        exit 0
    fi

    if echo "\$1" | grep -q -E '^(-h|--help|help)$'; then
        usage "\$@"
        exit 0
    fi

    for pkgname in "\$@"; do
        webinstall "\$pkgname"
    done

    show_path_updates

}

__webi_main "\$@"

EOF

    chmod a+x "$HOME/.local/bin/webi"

    if [ -n "${WEBI_PKG-}" ]; then
        "$HOME/.local/bin/webi" "${WEBI_PKG}"
    else
        echo ""
        echo "Hmm... no WEBI_PKG was specified. This is probably an error in the script."
        echo ""
        echo "Please open an issue with this information: Package '${WEBI_PKG-}' on '$(uname -s)/$(uname -r) $(uname -m)'"
        echo "    https://github.com/webinstall/packages/issues"
        echo ""
    fi

}

__install_webi
