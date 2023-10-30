#!/bin/sh

__bootstrap_webi() {

    set -e
    set -u
    #set -x

    my_libc=''
    if ldd /bin/ls 2> /dev/null | grep -q 'musl' 2> /dev/null; then
        my_libc=' musl-native'
    fi

    #WEBI_PKG=
    #PKG_NAME=
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
    WEBI_UA="$(uname -s)/$(uname -r) $(uname -m)/unknown${my_libc}"
    WEBI_PKG_DOWNLOAD=""
    WEBI_DOWNLOAD_DIR="${HOME}/Downloads"
    if command -v xdg-user-dir > /dev/null; then
        WEBI_DOWNLOAD_DIR="$(xdg-user-dir DOWNLOAD)"
        if [ "${WEBI_DOWNLOAD_DIR}" = "${HOME}" ]; then
            WEBI_DOWNLOAD_DIR="${HOME}/Downloads"
        fi
    fi

    WEBI_PKG_PATH="${WEBI_DOWNLOAD_DIR}/webi/${PKG_NAME:-error}/${WEBI_VERSION:-latest}"

    export WEBI_HOST

    ##
    ## Set up tmp, download, and install directories
    ##

    WEBI_TMP=${WEBI_TMP:-"$(mktemp -d -t webinstall-"${WEBI_PKG-}".XXXXXXXX)"}
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

    # get the special formatted version
    # (i.e. "go is go1.14" while node is "node v12.10.8")
    my_versioned_name=""
    _webi_canonical_name() {
        if [ -n "$my_versioned_name" ]; then
            echo "$my_versioned_name"
            return 0
        fi

        if command -v pkg_format_cmd_version > /dev/null; then
            my_versioned_name="'$(pkg_format_cmd_version "$WEBI_VERSION")'"
        else
            my_versioned_name="'$pkg_cmd_name v$WEBI_VERSION'"
        fi

        echo "$my_versioned_name"
    }

    # Update symlinks as per $HOME/.local/opt and $HOME/.local/bin install paths.
    webi_link() {
        if command -v pkg_link > /dev/null; then
            pkg_link
            return 0
        fi

        if test -n "${WEBI_SINGLE}"; then
            rm -rf "$pkg_dst_cmd"
            ln -s "$pkg_src_cmd" "$pkg_dst_cmd"
        else
            # 'pkg_dst' will default to $HOME/.local/opt/<pkg>
            # 'pkg_src' will be the installed version,
            # such as to $HOME/.local/opt/<pkg>-<version>
            rm -rf "$pkg_dst"
            ln -s "$pkg_src" "$pkg_dst"
        fi
    }

    # detect if this program is already installed
    # or if an installed version may cause conflict
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
                my_dst_rel="$(
                    webi_sub_home "${pkg_dst}"
                )"
                printf "    %s" "${my_dst_rel}"
                if [ "${pkg_src_cmd}" != "${my_current_cmd}" ]; then
                    my_src_rel="$(
                        webi_sub_home "${pkg_src}"
                    )"
                    printf " => %s" "${my_src_rel}"
                fi
                echo ""
                exit 0
            fi
            if [ -x "$pkg_src_cmd" ]; then
                webi_link
                echo "switched to $my_canonical_name:"
                my_src_rel="$(
                    webi_sub_home "${pkg_src}"
                )"
                my_dst_rel="$(
                    webi_sub_home "${pkg_dst}"
                )"
                echo "    ${my_dst_rel} => ${my_src_rel}"
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

    webi_sub_home() { (
        my_rel=${HOME}
        my_abs=${1}
        echo "${my_abs}" | sed "s:^${my_rel}:~:"
    ); }

    # detect if file is downloaded, and how to download it
    webi_download() {
        # determine the url to download
        if [ -n "${1-}" ]; then
            my_url="${1}"
        else
            if [ "error" = "$WEBI_CHANNEL" ]; then
                # TODO pass back requested OS / Arch / Version
                echo >&2 "Error: no '$PKG_NAME' release for '${WEBI_OS-}' on '$WEBI_ARCH' as one of '$WEBI_FORMATS' by the tag '${WEBI_TAG-}'"
                echo >&2 "       '$PKG_NAME' is available for '$PKG_OSES' on '$PKG_ARCHES' as one of '$PKG_FORMATS'"
                echo >&2 "       (check that the package name and version are correct)"
                echo >&2 ""
                my_release_url="$(
                    echo "$WEBI_RELEASES" |
                        sed 's:\?.*::'
                )"
                echo >&2 "       Double check at ${my_release_url}"
                echo >&2 ""
                exit 1
            fi
            my_url="$WEBI_PKG_URL"
        fi

        # determine the location to download to
        if [ -n "${2-}" ]; then
            my_dl="${2}"
        else
            my_dl="${WEBI_PKG_PATH}/$WEBI_PKG_FILE"
        fi

        if [ -n "${3-}" ]; then
            my_dl_name="${3}"
        else
            my_dl_name="${PKG_NAME}"
        fi

        my_dl_rel="$(
            webi_sub_home "${my_dl}"
        )"

        WEBI_PKG_DOWNLOAD="${my_dl}"
        export WEBI_PKG_DOWNLOAD

        if [ -e "${my_dl}" ]; then
            echo "Found ${my_dl_rel}"
            return 0
        fi

        echo "Downloading ${my_dl_name} from"
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
        echo "Saved as ${my_dl_rel}"
    }

    # detect which archives can be used
    webi_extract() {
        (
            cd "$WEBI_TMP"

            my_dl_rel="$(
                webi_sub_home "${WEBI_PKG_PATH}/${WEBI_PKG_FILE}"
            )"
            if [ "tar" = "$WEBI_EXT" ]; then
                echo "Extracting ${my_dl_rel}"
                tar xf "${WEBI_PKG_PATH}/$WEBI_PKG_FILE"
            elif [ "zip" = "$WEBI_EXT" ]; then
                echo "Extracting ${my_dl_rel}"
                unzip "${WEBI_PKG_PATH}/$WEBI_PKG_FILE" > __unzip__.log
            elif [ "exe" = "$WEBI_EXT" ]; then
                echo "Moving ${my_dl_rel}"
                mv "${WEBI_PKG_PATH}/$WEBI_PKG_FILE" .
            elif [ "xz" = "$WEBI_EXT" ]; then
                echo "Inflating ${my_dl_rel}"
                unxz -c "${WEBI_PKG_PATH}/$WEBI_PKG_FILE" > "$(basename "$WEBI_PKG_FILE")"
            else
                echo "Failed to extract ${WEBI_PKG_PATH}/$WEBI_PKG_FILE"
                exit 1
            fi
        )
    }

    # use 'pathman' to update $HOME/.config/envman/PATH.env
    webi_path_add() {
        my_path="${1}"

        fn_envman_init

        # \v was chosen as it is extremely unlikely for a filename
        # \1 could be an even better choice, but needs more testing.
        # (currently tested working on: linux & mac)
        # "\0001" should also work
        my_delim="$(
            printf '\v'
        )"

        my_path_expanded="$(
            echo "${my_path}" |
                sed -e "s${my_delim}\$HOME${my_delim}$HOME${my_delim}g" \
                    -e "s${my_delim}\${HOME}${my_delim}$HOME${my_delim}g" \
                    -e "s${my_delim}^~/${my_delim}$HOME/${my_delim}g"
        )"

        # A gift for @adamcstephens.
        # See https://github.com/webinstall/webi-installers/issues/322
        case "${PATH}" in
            # matches whether the first, a middle, the last, or the only PATH entry
            "${my_path_expanded}":* | \
                *:"${my_path_expanded}":* | \
                *:"${my_path_expanded}" | \
                "${my_path_expanded}")

                if fn_is_defined_in_all_shells "${my_path}"; then
                    return 0
                fi
                ;;
            *) ;;
        esac

        my_path_export="$(
            echo "${my_path}" |
                sed -e "s${my_delim}${HOME}${my_delim}\$HOME${my_delim}g" \
                    -e "s${my_delim}\${HOME}${my_delim}\$HOME${my_delim}g" \
                    -e "s${my_delim}^~/${my_delim}\$HOME/${my_delim}g"
        )"

        my_export="export PATH=\"$my_path_export:\$PATH\""
        if grep -q -F "${my_export}" ~/.config/envman/PATH.env; then
            return 0
        fi

        echo "${my_export}" >> ~/.config/envman/PATH.env

        mkdir -p "$_webi_tmp"
        my_path_tilde="$(
            echo "${my_path}" |
                sed -e "s${my_delim}${HOME}${my_delim}~${my_delim}g"
        )"

        if ! test -f "$_webi_tmp/.PATH.env" ||
            ! grep -q -F "${my_path_tilde}" "$_webi_tmp/.PATH.env"; then
            echo "${my_path_tilde}" >> "$_webi_tmp/.PATH.env"
        fi
    }

    fn_envman_init() {
        mkdir -p ~/.config/envman/
        if ! test -e ~/.config/envman/PATH.env; then
            touch ~/.config/envman/PATH.env
        fi

        if ! test -e ~/.config/envman/load.sh; then
            # shellcheck disable=SC2016
            {
                echo '# Generated for envman. Do not edit.'
                echo 'for x in ~/.config/envman/*.env; do'
                echo '    my_basename="$(basename "${x}")"'
                echo '    if [ "*.env" = "${my_basename}" ]; then'
                echo '        continue'
                echo '    fi'
                echo ''
                echo '    # shellcheck source=/dev/null'
                echo '    . "${x}"'
                echo 'done'
            } > ~/.config/envman/load.sh
        fi

        if command -v sh > /dev/null; then
            if test -e ~/.profile; then
                if ! grep -q -F '/.config/envman/load.sh' ~/.profile; then
                    fn_echo_load_sh >> ~/.profile
                fi
            fi
        fi
        if command -v bash > /dev/null; then
            if test -e ~/.bashrc; then
                if ! grep -q -F '/.config/envman/load.sh' ~/.bashrc; then
                    fn_echo_load_sh >> ~/.bashrc
                fi
            fi
        fi
        if command -v zsh > /dev/null; then
            if test -e ~/.zshrc; then
                if ! grep -q -F '/.config/envman/load.sh' ~/.zshrc; then
                    fn_echo_load_sh >> ~/.zshrc
                fi
            fi
        fi

        if command -v fish > /dev/null; then
            if test ! -e ~/.config/envman/load.fish; then
                # shellcheck disable=SC2016
                {
                    echo '# Generated for envman. Do not edit.'
                    echo 'for x in ~/.config/envman/*.env'
                    echo '	  source "$x"'
                    echo 'end'
                } > ~/.config/envman/load.fish
            fi

            mkdir -p ~/.config/fish
            if test -e ~/.config/fish/config.fish; then
                touch ~/.config/fish/config.fish
            fi
            if ! grep -q -F '/.config/envman/load.fish' ~/.config/fish/config.fish; then
                fn_echo_load_fish >> ~/.config/fish/config.fish
            fi
        fi
    }

    fn_echo_load_fish() {
        echo ''
        echo '# Generated for envman. Do not edit.'
        # shellcheck disable=SC2016
        echo 'test -s "$HOME/.config/envman/load.fish"; and source "$HOME/.config/envman/load.fish"'
    }

    fn_echo_load_sh() {
        echo ''
        echo '# Generated for envman. Do not edit.'
        # shellcheck disable=SC2016
        echo '[ -s "$HOME/.config/envman/load.sh" ] && source "$HOME/.config/envman/load.sh"'
    }

    fn_is_defined_in_all_shells() {
        my_path="${1}"

        my_path_expanded="$(
            echo "${my_path}" |
                sed -e "s${my_delim}\$HOME|${my_delim}$HOME${my_delim}g" \
                    -e "s${my_delim}\${HOME}${my_delim}$HOME${my_delim}g" \
                    -e "s${my_delim}^~/${my_delim}$HOME/${my_delim}g"
        )"
        my_paths="$(
            echo "${my_path_expanded}"
            # $HOME/foo
            echo "${my_path_expanded}" |
                sed "s${my_delim}${HOME}${my_delim}\$HOME${my_delim}g"
            # ${HOME}/foo
            echo "${my_path_expanded}" |
                sed "s${my_delim}${HOME}${my_delim}\${HOME}${my_delim}g"
            echo "${my_path}"
        )"

        my_confs="$(
            echo "${HOME}/.profile"
            echo "${HOME}/.bashrc"
            echo "${HOME}/.zshrc"
            echo "${HOME}/.config/fish/config.fish"
        )"
        for my_conf in $my_confs; do
            if test -e "${my_conf}"; then
                if ! grep -q -F "${my_paths}" "${my_conf}"; then
                    return 1
                fi
            fi
        done
    }

    # group common pre-install tasks as default
    webi_pre_install() {
        webi_check
        webi_download
        webi_extract
    }

    # move commands from the extracted archive directory
    # to $HOME/.local/opt or $HOME/.local/bin
    webi_install() {
        if test -n "${WEBI_SINGLE}"; then
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
        if command -v spctl > /dev/null && command -v xattr > /dev/null; then
            # note: some packages contain files that cannot be affected by xattr
            xattr -r -d com.apple.quarantine "$pkg_src" || true
            return 0
        fi
    }

    _webi_done_message() {
        my_dst_rel="$(
            webi_sub_home "${pkg_dst_cmd}"
        )"
        my_canonical_name="$(
            _webi_canonical_name
        )"
        echo "Installed ${my_canonical_name} as ${my_dst_rel}"
    }

    ##
    ##
    ## BEGIN custom override functions from <package>/install.sh
    ##
    ##

    WEBI_SINGLE=

    if [ -z "${WEBI_WELCOME-}" ]; then
        echo ""
        printf "Thanks for using webi to install '\e[32m%s\e[0m' on '\e[33m%s/%s\e[0m'.\n" "${WEBI_PKG-}" "$(uname -s)" "$(uname -m)"
        echo "Have a problem? Experience a bug? Please let us know:"
        printf "        \e[2m\e[36mhttps://github.com/webinstall/webi-installers/issues\e[0m\n"
        echo ""
        printf "\e[35mLovin'\e[0m it? Say thanks with a \e[1m\e[33mStar on GitHub\e[0m:\n"
        printf "        \e[36mhttps://github.com/webinstall/webi-installers\e[0m\n"
        echo ""
    fi

    WEBI_WELCOME=true
    export WEBI_WELCOME

    __init_installer() {
        # the installer will be injected here
        # {{ installer }}

        return 0
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
        [ -n "${WEBI_SINGLE-}" ] ||
        [ -n "${pkg_cmd_name-}" ] ||
        [ -n "${pkg_dst_cmd-}" ] ||
        [ -n "${pkg_dst_dir-}" ] ||
        [ -n "${pkg_dst-}" ] ||
        [ -n "${pkg_src_cmd-}" ] ||
        [ -n "${pkg_src_dir-}" ] ||
        [ -n "${pkg_src-}" ]; then

        pkg_cmd_name="${pkg_cmd_name:-$PKG_NAME}"

        pkg_no_exec="${pkg_no_exec:-}"

        if [ -n "${pkg_no_exec}" ]; then
            pkg_dst_cmd="${pkg_dst}"
            pkg_src="${pkg_dst}"
            pkg_src_cmd="${pkg_dst}"
        elif [ -n "${WEBI_SINGLE}" ]; then
            pkg_dst_cmd="${pkg_dst_cmd:-$HOME/.local/bin/$pkg_cmd_name}"
            pkg_dst="$pkg_dst_cmd"

            #pkg_src_cmd="${pkg_src_cmd:-$HOME/.local/opt/$pkg_cmd_name-v$WEBI_VERSION/bin/$pkg_cmd_name-v$WEBI_VERSION}"
            pkg_src_cmd="${pkg_src_cmd:-$HOME/.local/opt/$pkg_cmd_name-v$WEBI_VERSION/bin/$pkg_cmd_name}"
            pkg_src="$pkg_src_cmd"
        else
            pkg_dst="${pkg_dst:-$HOME/.local/opt/$pkg_cmd_name}"
            pkg_dst_cmd="${pkg_dst_cmd:-$pkg_dst/bin/$pkg_cmd_name}"

            pkg_src="${pkg_src:-$HOME/.local/opt/$pkg_cmd_name-v$WEBI_VERSION}"
            pkg_src_cmd="${pkg_src_cmd:-$pkg_src/bin/$pkg_cmd_name}"
        fi
        # shellcheck disable=SC2034 # used in ${WEBI_PKG}/install.sh
        pkg_src_bin="$(dirname "$pkg_src_cmd")"
        # shellcheck disable=SC2034 # used in ${WEBI_PKG}/install.sh
        pkg_dst_bin="$(dirname "$pkg_dst_cmd")"

        if command -v pkg_pre_install > /dev/null; then pkg_pre_install; else webi_pre_install; fi

        (
            cd "$WEBI_TMP"
            my_src_rel="$(
                webi_sub_home "${pkg_src_cmd}"
            )"
            if test -e "${pkg_src_cmd}"; then
                echo "Found ${my_src_rel} (remove to force reinstall)"
            else
                echo "Installing to ${my_src_rel}"
                if command -v pkg_install > /dev/null; then pkg_install; else webi_install; fi
                chmod a+x "$pkg_src"
                chmod a+x "$pkg_src_cmd"
            fi
        )

        webi_link

        if test -z "${pkg_no_exec}"; then
            _webi_enable_exec
        fi
        (
            cd "$WEBI_TMP"
            if command -v pkg_post_install > /dev/null; then pkg_post_install; else webi_post_install; fi
        )

        (
            cd "$WEBI_TMP"
            if command -v pkg_done_message > /dev/null; then pkg_done_message; else _webi_done_message; fi
        )

        echo ""
    fi

    webi_path_add "$HOME/.local/bin"
    if [ -z "${_WEBI_CHILD-}" ] && [ -f "$_webi_tmp/.PATH.env" ]; then
        if test -s "$_webi_tmp/.PATH.env"; then
            printf 'PATH.env updated with:\n'
            sort -u "$_webi_tmp/.PATH.env" | while read -r my_new_path; do
                echo "        ${my_new_path}"
            done
            printf "\n"

            rm -f "$_webi_tmp/.PATH.env"

            printf "\e[1m\e[35mTO FINISH\e[0m: copy, paste & run the following command:\n"
            printf "\n"
            printf "        \e[1m\e[32msource ~/.config/envman/PATH.env\e[0m\n"
            printf "        (newly opened terminal windows will update automatically)\n"
        fi
    fi

    rm -rf "$WEBI_TMP"
}

__bootstrap_webi
