#!/bin/bash

# shellcheck disable=2001
# because I prefer to use sed rather than bash replace
# (there's too little space in my head to learn both syntaxes)

__bootstrap_webi() {

    set -e
    set -u
    #set -x

    #WEBI_PKG=
    #PKG_NAME=
    # TODO should this be BASEURL instead?
    #WEBI_OS=
    #WEBI_ARCH=
    #WEBI_HOST=
    #WEBI_RELEASES=
    #WEBI_CSV=
    #WEBI_TAG=
    #WEBI_VERSION=
    #WEBI_MAJOR=
    #WEBI_MINOR=
    #WEBI_PATCH=
    # TODO not sure if BUILD is the best name for this
    #WEBI_BUILD=
    #WEBI_LTS=
    #WEBI_CHANNEL=
    #WEBI_EXT=
    #WEBI_FORMATS=
    #WEBI_PKG_URL=
    #WEBI_PKG_FILE=
    #PKG_OSES=
    #PKG_ARCHES=
    #PKG_FORMATS=
    WEBI_UA="$(uname -a)"
    WEBI_PKG_DOWNLOAD=""
    WEBI_PKG_PATH="${HOME}/Downloads/webi/${PKG_NAME:-error}/${WEBI_VERSION:-latest}"
    export WEBI_HOST

    ##
    ## Set up tmp, download, and install directories
    ##

    WEBI_TMP=${WEBI_TMP:-"$(mktemp -d -t webinstall-"${WEBI_PKG:-}".XXXXXXXX)"}
    export _webi_tmp="${_webi_tmp:-"$HOME/.local/opt/webi-tmp.d"}"

    mkdir -p "${WEBI_PKG_PATH}"
    mkdir -p "$HOME/.local/bin"
    mkdir -p "$HOME/.local/opt"

    ##
    ## Detect http client
    ##
    set +e
    WEBI_CURL="$(command -v curl)"
    export WEBI_CURL
    WEBI_WGET="$(command -v wget)"
    export WEBI_WGET
    set -e

    # get the special formatted version (i.e. "go is go1.14" while node is "node v12.10.8")
    my_versioned_name=""
    _webi_canonical_name() {
        if [ -n "$my_versioned_name" ]; then
            echo "$my_versioned_name"
            return 0
        fi

        if [ -n "$(command -v pkg_format_cmd_version)" ]; then
            my_versioned_name="'$(pkg_format_cmd_version "$WEBI_VERSION")'"
        else
            my_versioned_name="'$pkg_cmd_name v$WEBI_VERSION'"
        fi

        echo "$my_versioned_name"
    }

    # update symlinks according to $HOME/.local/opt and $HOME/.local/bin install paths.
    # shellcheck disable=2120
    # webi_link may be used in the templated install script
    webi_link() {
        if [ -n "$(command -v pkg_link)" ]; then
            pkg_link
            return 0
        fi

        if [ -n "$WEBI_SINGLE" ] || [ "single" = "${1:-}" ]; then
            rm -rf "$pkg_dst_cmd"
            ln -s "$pkg_src_cmd" "$pkg_dst_cmd"
        else
            # 'pkg_dst' will default to $HOME/.local/opt/<pkg>
            # 'pkg_src' will be the installed version, such as to $HOME/.local/opt/<pkg>-<version>
            rm -rf "$pkg_dst"
            ln -s "$pkg_src" "$pkg_dst"
        fi
    }

    # detect if this program is already installed or if an installed version may cause conflict
    webi_check() {
        # Test for existing version
        set +e
        my_path="$PATH"
        PATH="$(dirname "$pkg_dst_cmd"):$PATH"
        export PATH
        my_current_cmd="$(command -v "$pkg_cmd_name")"
        set -e
        if [ -n "$my_current_cmd" ]; then
            my_canonical_name="$(_webi_canonical_name)"
            if [ "$my_current_cmd" != "$pkg_dst_cmd" ]; then
                echo >&2 "WARN: possible PATH conflict between $my_canonical_name and currently installed version"
                echo >&2 "    ${pkg_dst_cmd} (new)"
                echo >&2 "    ${my_current_cmd} (existing)"
                #my_current_version=false
            fi
            # 'readlink' can't read links in paths on macOS 🤦
            # but that's okay, 'cmp -s' is good enough for us
            if cmp -s "${pkg_src_cmd}" "${my_current_cmd}"; then
                echo "${my_canonical_name} already installed:"
                printf "    %s" "${pkg_dst}"
                if [ "${pkg_src_cmd}" != "${my_current_cmd}" ]; then
                    printf " => %s" "${pkg_src}"
                fi
                echo ""
                exit 0
            fi
            if [ -x "$pkg_src_cmd" ]; then
                # shellcheck disable=2119
                # this function takes no args
                webi_link
                echo "switched to $my_canonical_name:"
                echo "    ${pkg_dst} => ${pkg_src}"
                exit 0
            fi
        fi
        export PATH="$my_path"
    }

    is_interactive_shell() {
        # $- shows shell flags (error,unset,interactive,etc)
        case $- in
            *i*)
                # true
                return 0
                ;;
            *)
                # false
                return 1
                ;;
        esac
    }

    # detect if file is downloaded, and how to download it
    webi_download() {
        # determine the url to download
        if [ -n "${1:-}" ]; then
            my_url="$1"
        else
            if [ "error" = "$WEBI_CHANNEL" ]; then
                # TODO pass back requested OS / Arch / Version
                echo >&2 "Error: no '$PKG_NAME' release for '${WEBI_OS:-}' on '$WEBI_ARCH' as one of '$WEBI_FORMATS' by the tag '${WEBI_TAG:-}'"
                echo >&2 "       '$PKG_NAME' is available for '$PKG_OSES' on '$PKG_ARCHES' as one of '$PKG_FORMATS'"
                echo >&2 "       (check that the package name and version are correct)"
                echo >&2 ""
                echo >&2 "       Double check at $(echo "$WEBI_RELEASES" | sed 's:\?.*::')"
                echo >&2 ""
                exit 1
            fi
            my_url="$WEBI_PKG_URL"
        fi

        # determine the location to download to
        if [ -n "${2:-}" ]; then
            my_dl="$2"
        else
            my_dl="${WEBI_PKG_PATH}/$WEBI_PKG_FILE"
        fi

        WEBI_PKG_DOWNLOAD="${my_dl}"
        export WEBI_PKG_DOWNLOAD

        if [ -e "$my_dl" ]; then
            echo "Found $my_dl"
            return 0
        fi

        echo "Downloading $PKG_NAME from"
        echo "$my_url"

        # It's only 2020, we can't expect to have reliable CLI tools
        # to tell us the size of a file as part of a base system...
        if [ -n "$WEBI_WGET" ]; then
            # wget has resumable downloads
            # TODO wget -c --content-disposition "$my_url"
            set +e
            my_show_progress=""
            if is_interactive_shell; then
                my_show_progress="--show-progress"
            fi
            if ! wget -q $my_show_progress --user-agent="wget $WEBI_UA" -c "$my_url" -O "$my_dl.part"; then
                echo >&2 "failed to download from $WEBI_PKG_URL"
                exit 1
            fi
            set -e
        else
            # Neither GNU nor BSD curl have sane resume download options, hence we don't bother
            # TODO curl -fsSL --remote-name --remote-header-name --write-out "$my_url"
            my_show_progress="-#"
            if is_interactive_shell; then
                my_show_progress=""
            fi
            # shellcheck disable=SC2086
            # we want the flags to be split
            curl -fSL $my_show_progress -H "User-Agent: curl $WEBI_UA" "$my_url" -o "$my_dl.part"
        fi
        mv "$my_dl.part" "$my_dl"

        echo ""
        echo "Saved as $my_dl"
    }

    # detect which archives can be used
    webi_extract() {
        pushd "$WEBI_TMP" > /dev/null 2>&1
        if [ "tar" = "$WEBI_EXT" ]; then
            echo "Extracting ${WEBI_PKG_PATH}/$WEBI_PKG_FILE"
            tar xf "${WEBI_PKG_PATH}/$WEBI_PKG_FILE"
        elif [ "zip" = "$WEBI_EXT" ]; then
            echo "Extracting ${WEBI_PKG_PATH}/$WEBI_PKG_FILE"
            unzip "${WEBI_PKG_PATH}/$WEBI_PKG_FILE" > __unzip__.log
        elif [ "exe" = "$WEBI_EXT" ]; then
            echo "Moving ${WEBI_PKG_PATH}/$WEBI_PKG_FILE"
            mv "${WEBI_PKG_PATH}/$WEBI_PKG_FILE" .
        elif [ "xz" = "$WEBI_EXT" ]; then
            echo "Inflating ${WEBI_PKG_PATH}/$WEBI_PKG_FILE"
            unxz -c "${WEBI_PKG_PATH}/$WEBI_PKG_FILE" > "$(basename "$WEBI_PKG_FILE")"
        else
            # do nothing
            echo "Failed to extract ${WEBI_PKG_PATH}/$WEBI_PKG_FILE"
            exit 1
        fi
        popd > /dev/null 2>&1
    }

    # use 'pathman' to update $HOME/.config/envman/PATH.env
    webi_path_add() {
        # make sure that we don't recursively install pathman with webi
        my_path="$PATH"
        export PATH="$HOME/.local/bin:$PATH"

        # install pathman if not already installed
        if [ -z "$(command -v pathman)" ]; then
            "$HOME/.local/bin/webi" pathman > /dev/null
        fi

        export PATH="$my_path"

        # in case pathman was recently installed and the PATH not updated
        mkdir -p "$_webi_tmp"
        # 'true' to prevent "too few arguments" output on bash
        # when there are 0 lines of stdout
        "$HOME/.local/bin/pathman" add "$1" |
            grep "export" 2> /dev/null \
                >> "$_webi_tmp/.PATH.env" ||
            true
    }

    # group common pre-install tasks as default
    webi_pre_install() {
        webi_check
        webi_download
        webi_extract
    }

    # move commands from the extracted archive directory to $HOME/.local/opt or $HOME/.local/bin
    # shellcheck disable=2120
    # webi_install may be sourced and used elsewhere
    webi_install() {
        if [ -n "$WEBI_SINGLE" ] || [ "single" = "${1:-}" ]; then
            mkdir -p "$(dirname "$pkg_src_cmd")"
            mv ./"$pkg_cmd_name"* "$pkg_src_cmd"
        else
            rm -rf "$pkg_src"
            mv ./"$pkg_cmd_name"* "$pkg_src"
        fi
    }

    # run post-install functions - just updating PATH by default
    webi_post_install() {
        webi_path_add "$(dirname "$pkg_dst_cmd")"
    }

    _webi_enable_exec() {
        if [ -n "$(command -v spctl)" ] && [ -n "$(command -v xattr)" ]; then
            # note: some packages contain files that cannot be affected by xattr
            xattr -r -d com.apple.quarantine "$pkg_src" || true
            return 0
        fi
        # TODO need to test that the above actually worked
        # (and proceed to this below if it did not)
        if [ -n "$(command -v spctl)" ]; then
            echo "Checking permission to execute '$pkg_cmd_name' on macOS 11+"
            set +e
            is_allowed="$(spctl -a "$pkg_src_cmd" 2>&1 | grep valid)"
            set -e
            if [ -z "$is_allowed" ]; then
                echo ""
                echo "##########################################"
                echo "#  IMPORTANT: Permission Grant Required  #"
                echo "##########################################"
                echo ""
                echo "Requesting permission to execute '$pkg_cmd_name' on macOS 10.14+"
                echo ""
                sleep 3
                spctl --add "$pkg_src_cmd"
            fi
        fi
    }

    # a friendly message when all is well, showing the final install path in $HOME/.local
    _webi_done_message() {
        echo "Installed $(_webi_canonical_name) as $pkg_dst_cmd"
    }

    ##
    ##
    ## BEGIN custom override functions from <package>/install.sh
    ##
    ##

    WEBI_SINGLE=

    if [ -z "${WEBI_WELCOME:-}" ]; then
        echo ""
        printf "Thanks for using webi to install '\e[32m${WEBI_PKG:-}\e[0m' on '\e[31m$(uname -s)/$(uname -m)\e[0m'.\n"
        echo "Have a problem? Experience a bug? Please let us know:"
        echo "        https://github.com/webinstall/webi-installers/issues"
        echo ""
        printf "\e[31mLovin'\e[0m it? Say thanks with a \e[34mStar on GitHub\e[0m:\n"
        printf "        \e[32mhttps://github.com/webinstall/webi-installers\e[0m\n"
        echo ""
    fi

    __init_installer() {

        # do nothing - to satisfy parser prior to templating
        printf ""

        # {{ installer }}

    }

    __init_installer

    ##
    ##
    ## END custom override functions
    ##
    ##

    # run everything with defaults or overrides as needed
    if command -v pkg_install > /dev/null ||
        command -v pkg_link > /dev/null ||
        command -v pkg_post_install > /dev/null ||
        command -v pkg_done_message > /dev/null ||
        command -v pkg_format_cmd_version > /dev/null ||
        [ -n "${WEBI_SINGLE:-}" ] ||
        [ -n "${pkg_cmd_name:-}" ] ||
        [ -n "${pkg_dst_cmd:-}" ] ||
        [ -n "${pkg_dst_dir:-}" ] ||
        [ -n "${pkg_dst:-}" ] ||
        [ -n "${pkg_src_cmd:-}" ] ||
        [ -n "${pkg_src_dir:-}" ] ||
        [ -n "${pkg_src:-}" ]; then

        pkg_cmd_name="${pkg_cmd_name:-$PKG_NAME}"

        if [ -n "$WEBI_SINGLE" ]; then
            pkg_dst_cmd="${pkg_dst_cmd:-$HOME/.local/bin/$pkg_cmd_name}"
            pkg_dst="$pkg_dst_cmd" # "$(dirname "$(dirname $pkg_dst_cmd)")"

            #pkg_src_cmd="${pkg_src_cmd:-$HOME/.local/opt/$pkg_cmd_name-v$WEBI_VERSION/bin/$pkg_cmd_name-v$WEBI_VERSION}"
            pkg_src_cmd="${pkg_src_cmd:-$HOME/.local/opt/$pkg_cmd_name-v$WEBI_VERSION/bin/$pkg_cmd_name}"
            pkg_src="$pkg_src_cmd" # "$(dirname "$(dirname $pkg_src_cmd)")"
        else
            pkg_dst="${pkg_dst:-$HOME/.local/opt/$pkg_cmd_name}"
            pkg_dst_cmd="${pkg_dst_cmd:-$pkg_dst/bin/$pkg_cmd_name}"

            pkg_src="${pkg_src:-$HOME/.local/opt/$pkg_cmd_name-v$WEBI_VERSION}"
            pkg_src_cmd="${pkg_src_cmd:-$pkg_src/bin/$pkg_cmd_name}"
        fi
        # this script is templated and these are used elsewhere
        # shellcheck disable=SC2034
        pkg_src_bin="$(dirname "$pkg_src_cmd")"
        # shellcheck disable=SC2034
        pkg_dst_bin="$(dirname "$pkg_dst_cmd")"

        if [ -n "$(command -v pkg_pre_install)" ]; then pkg_pre_install; else webi_pre_install; fi

        pushd "$WEBI_TMP" > /dev/null 2>&1
        echo "Installing to $pkg_src_cmd"
        if [ -n "$(command -v pkg_install)" ]; then pkg_install; else webi_install; fi
        chmod a+x "$pkg_src"
        chmod a+x "$pkg_src_cmd"
        popd > /dev/null 2>&1

        webi_link

        _webi_enable_exec
        pushd "$WEBI_TMP" > /dev/null 2>&1
        if [ -n "$(command -v pkg_post_install)" ]; then pkg_post_install; else webi_post_install; fi
        popd > /dev/null 2>&1

        pushd "$WEBI_TMP" > /dev/null 2>&1
        if [ -n "$(command -v pkg_done_message)" ]; then pkg_done_message; else _webi_done_message; fi
        popd > /dev/null 2>&1

        echo ""
    fi

    webi_path_add "$HOME/.local/bin"
    if [ -z "${_WEBI_CHILD:-}" ] && [ -f "$_webi_tmp/.PATH.env" ]; then
        if [ -n "$(cat "$_webi_tmp/.PATH.env")" ]; then
            printf 'PATH.env updated with:\n'
            sort -u "$_webi_tmp/.PATH.env"
            printf "\n"

            rm -f "$_webi_tmp/.PATH.env"

            printf "\e[31mTO FINISH\e[0m: copy, paste & run the following command:\n"
            printf "\n"
            printf "        \e[34msource ~/.config/envman/PATH.env\e[0m\n"
            printf "        (newly opened terminal windows will update automatically)\n"
        fi
    fi

    # cleanup the temp directory
    rm -rf "$WEBI_TMP"

    # See? No magic. Just downloading and moving files.

}

__bootstrap_webi
