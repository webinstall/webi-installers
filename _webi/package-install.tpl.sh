#!/bin/sh

__bootstrap_webi() {
    #PKG_NAME=
    #WEBI_OS=
    #WEBI_ARCH=
    #WEBI_LIBC=
    #WEBI_RELEASES=
    #WEBI_CSV=
    #WEBI_TAG=
    #WEBI_VERSION=
    #WEBI_MAJOR=
    #WEBI_MINOR=
    #WEBI_PATCH=
    # TODO not sure if BUILD is the best name for this
    #WEBI_BUILD=
    #WEBI_GIT_TAG=
    #WEBI_LTS=
    #WEBI_CHANNEL=
    #WEBI_EXT=
    #WEBI_FORMATS=
    #WEBI_PKG_URL=
    #WEBI_PKG_FILE=
    #WEBI_PKG_PATHNAME=
    #PKG_OSES=
    #PKG_ARCHES=
    #PKG_LIBCS=
    #PKG_FORMATS=
    #PKG_LATEST=
    WEBI_PKG_DOWNLOAD=""
    WEBI_DOWNLOAD_DIR="${HOME}/Downloads"
    if command -v xdg-user-dir > /dev/null; then
        WEBI_DOWNLOAD_DIR="$(xdg-user-dir DOWNLOAD)"
        if [ "${WEBI_DOWNLOAD_DIR}" = "${HOME}" ]; then
            WEBI_DOWNLOAD_DIR="${HOME}/Downloads"
        fi
    fi

    WEBI_PKG_PATH="${WEBI_DOWNLOAD_DIR}/webi/${PKG_NAME:-error}/${WEBI_VERSION:-latest}"

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
    webi_check_installed() {
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
                echo >&2 "    $(t_err "WARN: possible PATH conflict between $my_canonical_name and currently installed version")"
                echo >&2 "    $(t_path "${pkg_dst_cmd}") (new)"
                echo >&2 "    $(t_path "${my_current_cmd}") (existing)"
                #my_current_version=false
            fi
            # 'readlink' can't read links in paths on macOS 🤦
            # but that's okay, 'cmp -s' is good enough for us
            if cmp -s "${pkg_src_cmd}" "${my_current_cmd}"; then
                echo "    $(t_pkg "${my_canonical_name}") already installed:"
                my_dst_rel="$(fn_sub_home "${pkg_dst}")"
                printf "    %s" "$(t_link "${my_dst_rel}")"
                if [ "${pkg_src_cmd}" != "${my_current_cmd}" ]; then
                    my_src_rel="$(fn_sub_home "${pkg_src}")"
                    printf " => %s" "$(t_path "${my_src_rel}")"
                fi
                echo ""
                exit 0
            fi
            if [ -x "$pkg_src_cmd" ]; then
                webi_link
                echo "    Switched to ${my_canonical_name}:"
                my_src_rel="$(fn_sub_home "${pkg_src}")"
                my_dst_rel="$(fn_sub_home "${pkg_dst}")"
                echo "    $(t_link "${my_dst_rel}") => $(t_path "${my_src_rel}")"
                exit 0
            fi
        fi
        export PATH="$my_path"
    }

    webi_check_available() {
        if test "$WEBI_CHANNEL" != "error"; then
            return 0
        fi

        {
            echo ""
            echo "    $(t_err "Error: no '${PKG_NAME:-"Unknown Package"}@${WEBI_TAG:-"Unknown Tag"}' release for '${WEBI_OS:-"Unknown OS"}' (${WEBI_LIBC:-"Unknown Libc"}) on '${WEBI_ARCH:-"Unknown CPU"}' as one of '${WEBI_FORMATS:-"Unknown File Type"}'")"
            echo ""
            echo "        Latest Version: ${PKG_LATEST}"
            echo "        CPUs: $PKG_ARCHES"
            echo "        OSes: $PKG_OSES"
            echo "        libcs: $PKG_LIBCS"
            echo "        Package Formats: $PKG_FORMATS"
            echo "        (check that the package name and version are correct)"

            echo ""
            my_release_url="$(echo "$WEBI_RELEASES" | sed 's:?.*::')"
            my_release_params="$(echo "$WEBI_RELEASES" | sed 's:.*?:?:')"
            echo "      Double check at ${my_release_url}"
            echo "          ${my_release_params}"
            echo ""
        } >&2

        exit 1
    }

    # detect if file is downloaded, and how to download it
    webi_download() {
        my_url="${1}"
        my_dl="${2}"
        my_dl_name="${3:-${PKG_NAME}}"

        my_dl_rel="$(fn_sub_home "${my_dl}")"

        WEBI_PKG_DOWNLOAD="${my_dl}"
        export WEBI_PKG_DOWNLOAD

        if [ -e "${my_dl}" ]; then
            echo "    $(t_dim 'Found') $(t_path "${my_dl_rel}")"
            return 0
        fi
        echo "    Downloading $(t_pkg "${my_dl_name}") from"
        echo "      $(t_url "${my_url}")"
        fn_download_to_path "${my_url}" "${my_dl}"
        echo "    $(t_dim 'Saved as') $(t_path "${my_dl_rel}")"
    }

    webi_git_clone() { (
        my_url="${1}"
        my_dl="${2}"

        my_dl_rel="$(fn_sub_home "${my_dl}")"
        if [ -e "${my_dl}" ]; then
            echo "    $(t_dim 'Found') $(t_path "${my_dl_rel}")"

            cp -RPp "${my_dl}" "${WEBI_TMP}/${WEBI_PKG_FILE}/"
            return 0
        fi

        echo "    Cloning $(t_url "${my_url}")"
        cmd_git="git clone --config advice.detachedHead=false --quiet --depth=1 --single-branch"
        rm -rf "${my_dl}.part"
        if ! $cmd_git "${my_url}" --branch "${WEBI_GIT_TAG}" "${my_dl}.part"; then
            echo >&2 "    $(t_err "failed to git clone ${WEBI_PKG_URL}")"
            exit 1
        fi
        mv "${my_dl}.part" "${my_dl}"

        cp -RPp "${my_dl}" "${WEBI_TMP}/${WEBI_PKG_FILE}/"
    ); }

    # detect which archives can be used
    webi_extract() { (
        cd "$WEBI_TMP"

        my_dl_rel="$(
            fn_sub_home "${WEBI_PKG_PATH}/${WEBI_PKG_FILE}"
        )"
        if [ "tar" = "$WEBI_EXT" ]; then
            echo "    Extracting $(t_path "${my_dl_rel}")"
            tar xf "${WEBI_PKG_PATH}/$WEBI_PKG_FILE"
        elif [ "zip" = "$WEBI_EXT" ] || [ "app.zip" = "$WEBI_EXT" ]; then
            echo "    Extracting $(t_path "${my_dl_rel}")"
            unzip "${WEBI_PKG_PATH}/$WEBI_PKG_FILE" > __unzip__.log
        elif [ "exe" = "$WEBI_EXT" ]; then
            echo "    Moving $(t_path "${my_dl_rel}")"
            echo "      to $(t_path "$(fn_sub_home "$(pwd)")")"
            mv "${WEBI_PKG_PATH}/$WEBI_PKG_FILE" .
        elif [ "git" = "$WEBI_EXT" ]; then
            echo "    Moving $(t_path "${my_dl_rel}")"
            mv "${WEBI_PKG_PATH}/$WEBI_PKG_FILE" .
        elif [ "xz" = "$WEBI_EXT" ]; then
            echo "    Inflating $(t_path "${my_dl_rel}")"
            unxz -c "${WEBI_PKG_PATH}/$WEBI_PKG_FILE" > "$(basename "$WEBI_PKG_FILE")"
        else
            echo "    $(t_err 'Failed to extract') $(t_path "${WEBI_PKG_PATH}/$WEBI_PKG_FILE")"
            exit 1
        fi
    ); }

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

        touch -a ~/.config/envman/PATH.env
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
            if ! test -e "${my_conf}"; then
                continue
            fi

            if ! grep -q -F "${my_paths}" "${my_conf}"; then
                return 1
            fi
        done
    }

    # group common pre-install tasks as default
    webi_pre_install() {
        webi_check_installed
        webi_check_available
        if test "git" = "${WEBI_EXT}"; then
            webi_git_clone \
                "${WEBI_PKG_URL}" \
                "${WEBI_PKG_PATH}/${WEBI_PKG_FILE}"
            return 0
        fi
        webi_download \
            "${WEBI_PKG_URL}" \
            "${WEBI_PKG_PATH}/${WEBI_PKG_FILE}"
        webi_extract
    }

    # move commands from the extracted archive directory
    # to $HOME/.local/opt or $HOME/.local/bin
    webi_install() {
        b_src=''
        if test -n "${WEBI_SINGLE}"; then
            b_src="${pkg_src_cmd}"
            mkdir -p "$(dirname "$pkg_src_cmd")"
        else
            echo "    Removing $(t_path "${pkg_src}")"
            rm -rf "$pkg_src"
            b_src="${pkg_src}"
        fi

        echo "    Moving $(t_path "${pkg_cmd_name}")"
        echo "      to $(t_path "$(fn_sub_home "${b_src}")")"
        mv ./"${pkg_cmd_name}"* "${b_src}"
    }

    # run post-install functions - just updating PATH by default
    webi_post_install() {
        if test -n "${pkg_no_exec}"; then
            return 0
        fi

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
        my_dst_rel="$(fn_sub_home "${pkg_dst_cmd}")"
        my_canonical_name="$(_webi_canonical_name)"
        echo ""
        echo "    Installed $(t_pkg "${my_canonical_name}") as $(t_link "${my_dst_rel}")"
    }

    ##
    ## Set up tmp, download, and install directories
    ##

    WEBI_TMP=${WEBI_TMP:-"$(mktemp -d -t webinstall-"${WEBI_PKG-}".XXXXXXXX)"}
    export _webi_tmp="${_webi_tmp:-"$HOME/.local/opt/webi-tmp.d"}"

    mkdir -p "${WEBI_PKG_PATH}"
    mkdir -p "$HOME/.local/bin"
    mkdir -p "$HOME/.local/opt"

    if test -e ~/.local/bin; then
        echo "    $(t_dim 'Found') $(t_path ' ~/.local/bin')"
    else
        echo "    Creating$(t_path ' ~/.local/bin')"
        mkdir -p "$HOME/.local/bin"
    fi

    ##
    ##
    ## BEGIN custom override functions from <package>/install.sh
    ##
    ##

    WEBI_SINGLE=

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
                fn_sub_home "${pkg_src_cmd}"
            )"
            if test -e "${pkg_src_cmd}"; then
                echo "    $(t_dim 'Found') $(t_path "${my_src_rel}") $(t_dim '(remove to force reinstall)')"
            else
                echo "    Installing to $(t_path "${my_src_rel}")"
                if command -v pkg_install > /dev/null; then pkg_install; else webi_install; fi
                chmod a+x "$pkg_src"
                chmod a+x "$pkg_src_cmd"
            fi
        )

        if test -z "${pkg_no_exec}"; then
            webi_link
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
            # shellcheck disable=SC2088 # ~ should not expand here
            echo "    Edit $(t_path '~/.config/envman/PATH.env') to add:"
            sort -u "$_webi_tmp/.PATH.env" | while read -r my_new_path; do
                echo "        $(t_path "${my_new_path}")"
            done
            echo ""

            rm -f "$_webi_tmp/.PATH.env"

            echo ">>> $(t_info 'ACTION REQUIRED') <<<"
            echo "        Copy, paste & run the following command:"
            echo "        $(t_attn 'source ~/.config/envman/PATH.env')"
            echo "        (newly opened terminal windows will update automatically)"
            echo ""
        fi
    fi

    rm -rf "$WEBI_TMP"
}

#########################################
#                                       #
# Display Debug Info in Case of Failure #
#                                       #
#########################################

fn_show_welcome_back() { (
    if test -n "${WEBI_WELCOME:-}"; then
        return 0
    fi

    echo ""
    # invert t_task and t_pkg for top-level welcome message
    printf -- ">>> %s %s  <<<\n" \
        "$(t_pkg 'Welcome to') $(t_task 'Webi')$(t_pkg '!')" \
        "$(t_dim "- modern tools, instant installs.")"
    echo "    We expect your experience to be $(t_em 'absolutely perfect')!"
    echo ""
    echo "    $(t_attn 'Success')? Star it!   $(t_url 'https://github.com/webinstall/webi-installers')"
    echo "    $(t_attn 'Problem')? Report it: $(t_url 'https://github.com/webinstall/webi-installers/issues')"
    echo "                        $(t_dim "(your system is") $(t_host "$(fn_get_os)")/$(t_host "$(uname -m)") $(t_dim "with") $(t_host "$(fn_get_libc)") $(t_dim "&") $(t_host "$(fn_get_http_client_name)")$(t_dim ")")"

    sleep 0.2
); }

fn_get_os() { (
    # Ex:
    #     GNU/Linux
    #     Android
    #     Linux (often Alpine, musl)
    #     Darwin
    b_os="$(uname -o 2> /dev/null || echo '')"
    b_sys="$(uname -s)"
    if test -z "${b_os}" || test "${b_os}" = "${b_sys}"; then
        # ex: 'Darwin' (and plain, non-GNU 'Linux')
        echo "${b_sys}"
        return 0
    fi

    if echo "${b_os}" | grep -q "${b_sys}"; then
        # ex: 'GNU/Linux'
        echo "${b_os}"
        return 0
    fi

    # ex: 'Android/Linux'
    echo "${b_os}/${b_sys}"
); }

fn_get_libc() { (
    # Ex:
    #     musl
    #     libc
    if ldd /bin/ls 2> /dev/null | grep -q 'musl' 2> /dev/null; then
        echo 'musl'
    elif fn_get_os | grep -q 'GNU|Linux'; then
        echo 'gnu'
    else
        echo 'libc'
    fi
); }

fn_get_http_client_name() { (
    # Ex:
    #     curl
    #     curl+wget
    b_client=""
    if command -v curl > /dev/null; then
        b_client="curl"
    fi
    if command -v wget > /dev/null; then
        if test -z "${b_client}"; then
            b_client="wget"
        else
            b_client="curl+wget"
        fi
    fi

    echo "${b_client}"
); }

#########################################
#                                       #
#      For Making the Display Nice      #
#                                       #
#########################################

# Term Types
t_cmd() { (fn_printf '\e[2m\e[35m%s\e[39m\e[22m' "${1}"); }
t_host() { (fn_printf '\e[2m\e[33m%s\e[39m\e[22m' "${1}"); }
t_link() { (fn_printf '\e[1m\e[36m%s\e[39m\e[22m' "${1}"); }
t_path() { (fn_printf '\e[2m\e[32m%s\e[39m\e[22m' "${1}"); }
t_pkg() { (fn_printf '\e[1m\e[32m%s\e[39m\e[22m' "${1}"); }
t_task() { (fn_printf '\e[36m%s\e[39m' "${1}"); }
t_url() { (fn_printf '\e[2m%s\e[22m' "${1}"); }

# Levels
t_info() { (fn_printf '\e[1m\e[36m%s\e[39m\e[22m' "${1}"); }
t_attn() { (fn_printf '\e[1m\e[33m%s\e[39m\e[22m' "${1}"); }
t_warn() { (fn_printf '\e[1m\e[33m%s\e[39m\e[22m' "${1}"); }
t_err() { (fn_printf '\e[31m%s\e[39m' "${1}"); }

# Styles
t_bold() { (fn_printf '\e[1m%s\e[22m' "${1}"); }
t_dim() { (fn_printf '\e[2m%s\e[22m' "${1}"); }
t_em() { (fn_printf '\e[3m%s\e[23m' "${1}"); }
t_under() { (fn_printf '\e[4m%s\e[24m' "${1}"); }

# FG Colors
t_cyan() { (fn_printf '\e[36m%s\e[39m' "${1}"); }
t_green() { (fn_printf '\e[32m%s\e[39m' "${1}"); }
t_magenta() { (fn_printf '\e[35m%s\e[39m' "${1}"); }
t_yellow() { (fn_printf '\e[33m%s\e[39m' "${1}"); }

fn_printf() { (
    a_style="${1}"
    a_text="${2}"
    if fn_is_tty; then
        #shellcheck disable=SC2059
        printf -- "${a_style}" "${a_text}"
    else
        printf -- '%s' "${a_text}"
    fi
); }

fn_sub_home() { (
    my_rel=${HOME}
    my_abs=${1}
    echo "${my_abs}" | sed "s:^${my_rel}:~:"
); }

###################################
#                                 #
#       Detect HTTP Client        #
#                                 #
###################################

fn_wget() { (
    # Doc:
    #     Downloads the file at the given url to the given path
    a_url="${1}"
    a_path="${2}"

    cmd_wget="wget -c -q --user-agent"
    if fn_is_tty; then
        cmd_wget="wget -c -q --show-progress --user-agent"
    fi
    # busybox wget doesn't support --show-progress
    # See <https://github.com/webinstall/webi-installers/pull/772>
    if readlink "$(command -v wget)" | grep -q busybox; then
        cmd_wget="wget --user-agent"
    fi

    b_triple_ua="$(fn_get_target_triple_user_agent)"
    b_agent="webi/wget ${b_triple_ua}"
    if command -v curl > /dev/null; then
        b_agent="webi/wget+curl ${b_triple_ua}"
    fi

    if ! $cmd_wget "${b_agent}" "${a_url}" -O "${a_path}"; then
        echo >&2 "    $(t_err "failed to download (wget)") '$(t_url "${a_url}")'"
        echo >&2 "    $cmd_wget '${b_agent}' '${a_url}' -O '${a_path}'"
        echo >&2 "    $(wget -V)"
        return 1
    fi
); }

fn_curl() { (
    # Doc:
    #     Downloads the file at the given url to the given path
    a_url="${1}"
    a_path="${2}"

    cmd_curl="curl -f -sSL -#"
    if fn_is_tty; then
        cmd_curl="curl -f -sSL"
    fi

    b_triple_ua="$(fn_get_target_triple_user_agent)"
    b_agent="webi/curl ${b_triple_ua}"
    if command -v wget > /dev/null; then
        b_agent="webi/curl+wget ${b_triple_ua}"
    fi

    if ! $cmd_curl -A "${b_agent}" "${a_url}" -o "${a_path}"; then
        echo >&2 "    $(t_err "failed to download (curl)") '$(t_url "${a_url}")'"
        echo >&2 "    $cmd_curl -A '${b_agent}' '${a_url}' -o '${a_path}'"
        echo >&2 "    $(curl -V)"
        return 1
    fi
); }

fn_get_target_triple_user_agent() { (
    # Ex:
    #     x86_64/unknown GNU/Linux/5.15.107-2-pve gnu
    #     arm64/unknown Darwin/22.6.0 libc
    echo "$(uname -m)/unknown $(fn_get_os)/$(uname -r) $(fn_get_libc)"
); }

fn_download_to_path() { (
    a_url="${1}"
    a_path="${2}"

    mkdir -p "$(dirname "${a_path}")"
    if command -v curl > /dev/null; then
        fn_curl "${a_url}" "${a_path}.part"
    elif command -v wget > /dev/null; then
        fn_wget "${a_url}" "${a_path}.part"
    else
        echo >&2 "    $(t_err "failed to detect HTTP client (curl, wget)")"
        return 1
    fi
    mv "${a_path}.part" "${a_path}"
); }

##############################################
#                                            #
# Install or Update Webi and Install Package #
#                                            #
##############################################

webi_upgrade() { (
    a_path="${1}"

    b_path_rel="$(fn_sub_home "${a_path}")"
    b_checksum=""
    if test -r "${a_path}"; then
        b_checksum="$(fn_checksum "${a_path}")"
    fi
    if test "$b_checksum" = "${WEBI_CHECKSUM}"; then
        sleep 0.1
        return 0
    fi

    b_webi_file_url="${WEBI_HOST}/packages/webi/webi.sh"
    b_tmp=''
    if test -r "${a_path}"; then
        b_ts="$(date -u '+%s')"
        b_tmp="${a_path}.${b_ts}.bak"
        mv "${a_path}" "${b_tmp}"
        echo ""
        echo "$(t_task 'Updating') $(t_pkg 'Webi')"
    fi

    echo "    Downloading $(t_url "${b_webi_file_url}")"
    echo "        to $(t_path "${b_path_rel}")"
    fn_download_to_path "${b_webi_file_url}" "${a_path}"
    chmod u+x "${a_path}"

    if test -r "${b_tmp}"; then
        rm -f "${b_tmp}"
    fi
); }

fn_checksum() {
    a_filepath="${1}"

    cmd_shasum='sha1sum'
    if command -v shasum > /dev/null; then
        cmd_shasum='shasum'
    fi

    $cmd_shasum "${a_filepath}" | cut -d' ' -f1 | cut -c 1-8
}

##############################################
#                                            #
#          Detect TTY and run main           #
#                                            #
##############################################

fn_is_tty() {
    if test "${WEBI_TTY}" = 'tty'; then
        return 0
    fi
    return 1
}

fn_detect_tty() { (
    # stdin will NOT be a tty if it's being piped
    # stdout & stderr WILL be a tty even when piped
    # they are not a tty if being captured or redirected
    # 'set -i' is NOT available in sh
    if test -t 1 && test -t 2; then
        return 0
    fi

    return 1
); }

main() { (
    set -e
    set -u
    #set -x

    export WEBI_HOST=
    export WEBI_CHECKSUM=
    export WEBI_PKG=

    WEBI_TTY="${WEBI_TTY:-}"
    if test -z "${WEBI_TTY}"; then
        if fn_detect_tty; then
            WEBI_TTY="tty"
        fi
        export WEBI_TTY
    fi

    if test -z "${WEBI_WELCOME:-}"; then
        fn_show_welcome_back
    fi
    export WEBI_WELCOME='shown'

    # note: we may support custom locations in the future
    export WEBI_HOME="${HOME}/.local"
    b_webi_path="${WEBI_HOME}/bin/webi"

    WEBI_CURRENT="${WEBI_CURRENT:-}"
    if test "${WEBI_CURRENT}" != "${WEBI_CHECKSUM}"; then
        webi_upgrade "${b_webi_path}"
        export WEBI_CURRENT="${WEBI_CHECKSUM}"
    fi

    echo "$(t_task 'Installing') $(t_pkg "${WEBI_PKG}") $(t_task '...')"
    __bootstrap_webi
); }

##############################################
#                                            #
#          envman helper functions           #
#                                            #
##############################################

fn_envman_init() { (
    if ! test -r ~/.config/envman/; then
        echo "    Initializing ~/.config/envman/"
        mkdir -p ~/.config/envman/
    fi

    # Note: the variables $BASH, $ZSH_NAME, etc are always empty
    # because the active shell is always sh when this script runs
    fn_envman_init_load_sh
    fn_envman_init_shell sh '.profile' '.ash_history'
    fn_envman_init_shell bash '.bashrc' '.bash_history'
    fn_envman_init_shell zsh '.zshrc' '.zsh_sessions'

    if command -v fish > /dev/null; then
        fn_envman_init_load_fish
        fn_envman_init_fish
    fi
); }

fn_envman_init_load_sh() { (
    touch -a ~/.config/envman/load.sh
    if grep -q -F 'ENVMAN_LOAD' ~/.config/envman/load.sh; then
        return 0
    fi

    cat << LOAD_SH > ~/.config/envman/load.sh
# Generated for envman. Do not edit.
# shellcheck disable=SC1090

touch -a ~/.config/envman/PATH.env
touch -a ~/.config/envman/ENV.env
touch -a ~/.config/envman/alias.env
touch -a ~/.config/envman/function.sh

# ENV first because we may use it in PATH
test -z "\${ENVMAN_LOAD:-}" && . ~/.config/envman/ENV.env
test -z "\${ENVMAN_LOAD:-}" && . ~/.config/envman/PATH.env

export ENVMAN_LOAD='loaded'

# function first because we may use it in alias
test -z "\${g_envman_load_sh:-}" && . ~/.config/envman/function.sh
test -z "\${g_envman_load_sh:-}" && . ~/.config/envman/alias.env

g_envman_load_sh='loaded'
LOAD_SH

); }

fn_envman_init_shell() { (
    a_shell="${1}"
    a_rc="${2}"
    a_history="${3:-_history_file_doesnt_exist}"
    a_login_shell="$(basename "${SHELL:-}")"

    if ! command -v "${a_shell}" > /dev/null; then
        return 0
    fi

    # .bashrc and .zshrc no longer exist by default on macOS
    if ! test -e ~/"${a_rc}" && ! test -e ~/"${a_history}"; then
        if test "${a_login_shell}" != "${a_shell}"; then
            return 0
        fi
    fi

    touch -a ~/"${a_rc}"
    if grep -q -F '/.config/envman/load.sh' ~/"${a_rc}"; then
        return 0
    fi

    # shellcheck disable=SC2088 # ~ should not expand here
    echo >&2 "    Edit $(t_path "~/${a_rc}") to $(t_cmd "source ~/.config/envman/load.sh")"
    {
        echo ''
        echo '# Generated for envman. Do not edit.'
        #shellcheck disable=SC2016 # vars should not expand here
        echo '[ -s "$HOME/.config/envman/load.sh" ] && source "$HOME/.config/envman/load.sh"'
    } >> ~/"${a_rc}"
); }

fn_envman_init_load_fish() { (
    mkdir -p ~/.config/envman/

    touch -a ~/.config/envman/load.fish
    if grep -q -F 'ENVMAN_LOAD' ~/.config/envman/load.fish; then
        return 0
    fi

    echo >&2 "    Create ~/.config/envman/load.fish"

    cat << EOF > ~/.config/envman/load.fish
# Generated for envman. Do not edit.

touch -a ~/.config/envman/PATH.env
touch -a ~/.config/envman/ENV.env
touch -a ~/.config/envman/alias.env
touch -a ~/.config/envman/function.fish

not set -q ENVMAN_LOAD; and source ~/.config/envman/ENV.env
not set -q ENVMAN_LOAD; and source ~/.config/envman/PATH.env

set -x ENVMAN_LOAD 'loaded'

not set -q g_envman_load_fish; and source ~/.config/envman/function.fish
not set -q g_envman_load_fish; and source ~/.config/envman/alias.env

set -g g_envman_load_fish 'loaded'
EOF

); }

fn_envman_init_fish() {
    mkdir -p ~/.config/fish/

    touch -a ~/.config/fish/config.fish
    if grep -q -F '/.config/envman/load.fish' ~/.config/fish/config.fish; then
        return 0
    fi

    # shellcheck disable=SC2088 # ~ should not expand here
    echo >&2 "    Edit $(t_path "~/.config/fish/config.fish") to $(t_cmd "source ~/.config/envman/load.fish")"

    cat << EOF >> ~/.config/fish/config.fish

# Generated for envman. Do not edit.
test -s ~/.config/envman/load.fish; and source ~/.config/envman/load.fish
EOF

}

main
