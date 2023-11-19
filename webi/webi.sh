#!/bin/sh
set -e
set -u
#set -x

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
    echo "                        $(t_dim "(your system is") $(t_host "$(uname -s)")/$(t_host "$(uname -m)") $(t_dim "with") $(t_host "$(fn_get_libc)") $(t_dim "&") $(t_host "$(fn_get_http_client_name)")$(t_dim ")")"

    sleep 0.2
); }

fn_get_libc() { (
    # Ex:
    #     musl
    #     libc
    if ldd /bin/ls 2> /dev/null | grep -q 'musl' 2> /dev/null; then
        echo 'musl'
    elif uname -o | grep -q 'GNU' || uname -s | grep -q 'Linux'; then
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

    cmd_wget="wget -q --user-agent"
    if fn_is_tty; then
        cmd_wget="wget -q --show-progress --user-agent"
    fi

    b_triple_ua="$(fn_get_target_triple_user_agent)"
    b_agent="webi/wget ${b_triple_ua}"
    if command -v curl > /dev/null; then
        b_agent="webi/wget+curl ${b_triple_ua}"
    fi

    if ! $cmd_wget "${b_agent}" -c "${a_url}" -O "${a_path}"; then
        echo >&2 "    $(t_err "failed to download (wget)") '$(t_url "${a_url}")'"
        echo >&2 "    $cmd_wget '${b_agent}' -c '${a_url}' -O '${a_path}'"
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
    #     x86_64/unknown Linux/5.15.107-2-pve gnu
    #     arm64/unknown Darwin/22.6.0 libc
    echo "$(uname -m)/unknown $(uname -s)/$(uname -r) $(fn_get_libc)"
); }

fn_download_to_path() { (
    a_url="${1}"
    a_path="${2}"

    mkdir -p "$(dirname "${a_path}")"
    if command -v wget > /dev/null; then
        fn_wget "${a_url}" "${a_path}.part"
    elif command -v curl > /dev/null; then
        fn_curl "${a_url}" "${a_path}.part"
    else
        echo >&2 "    $(t_err "failed to detect HTTP client (curl, wget)")"
        return 1
    fi
    mv "${a_path}.part" "${a_path}"
); }

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

__webi_main() {

    my_date="$(date +%F_%H-%M-%S)"
    export WEBI_TIMESTAMP="${my_date}"
    export _webi_tmp="${_webi_tmp:-$(
        mktemp -d -t "webi-$WEBI_TIMESTAMP.XXXXXXXX"
    )}"

    if [ -n "${_WEBI_PARENT:-}" ]; then
        export _WEBI_CHILD=true
    else
        export _WEBI_CHILD=
    fi
    export _WEBI_PARENT=true

    my_os="$(uname -s)"
    my_arch="$(uname -m)"

    ##
    ## Detect acceptable package formats
    ##

    my_ext=""
    set +e
    # NOTE: the order here is least favorable to most favorable
    if [ -n "$(command -v pkgutil)" ]; then
        my_ext="pkg,$my_ext"
    fi
    # disable this check for the sake of building the macOS installer on Linux
    #if [ -n "$(command -v diskutil)" ]; then
    # note: could also detect via hdiutil
    my_ext="dmg,$my_ext"
    #fi
    if [ -n "$(command -v git)" ]; then
        my_ext="git,$my_ext"
    fi
    if [ -n "$(command -v unxz)" ]; then
        my_ext="xz,$my_ext"
    fi
    if [ -n "$(command -v unzip)" ]; then
        my_ext="zip,$my_ext"
    fi
    # for mac/linux 'exe' refers to the uncompressed binary without extension
    my_ext="exe,$my_ext"
    if [ -n "$(command -v tar)" ]; then
        my_ext="tar,$my_ext"
    fi
    my_ext="$(echo "$my_ext" | sed 's/,$//')" # nix trailing comma
    set -e

    ##
    ## Detect http client
    ##

    set +e
    WEBI_CURL="$(command -v curl)"
    export WEBI_URL
    WEBI_WGET="$(command -v wget)"
    export WEBI_WGET
    set -e

    my_libc=''
    if ldd /bin/ls 2> /dev/null | grep -q 'musl' 2> /dev/null; then
        my_libc='musl'
    elif uname -o | grep -q 'GNU' || uname -s | grep -q 'Linux'; then
        my_libc='gnu'
    else
        my_libc='libc'
    fi

    export WEBI_HOST="${WEBI_HOST:-https://webinstall.dev}"

    # ex: Darwin or Linux
    my_sys="$(uname -s)"
    # ex: 22.6.0
    my_rev="$(uname -r)"
    # ex: arm64
    my_machine="$(uname -m)"

    export WEBI_UA="${my_sys}/${my_rev} ${my_machine}/unknown ${my_libc}"

    webinstall() {

        b_package="${1:-}"
        if test -z "${b_package}"; then
            echo >&2 "Usage: webi <package>@<version> ..."
            echo >&2 "Example: webi node@lts rg"
            exit 1
        fi

        b_install_tmpdir="$(
            mktemp -d -t "${b_package}-install.${WEBI_TIMESTAMP}.XXXXXXXX"
        )"

        my_installer_url="$WEBI_HOST/api/installers/${b_package}.sh?formats=${my_ext}"
        if [ -n "$WEBI_CURL" ]; then
            if ! curl -fsSL "$my_installer_url" -H "User-Agent: curl $WEBI_UA" \
                -o "${b_install_tmpdir}/${b_package}-install.sh"; then
                echo >&2 "error fetching '$my_installer_url'"
                exit 1
            fi
        else
            if ! wget -q "$my_installer_url" --user-agent="wget $WEBI_UA" \
                -O "${b_install_tmpdir}/${b_package}-install.sh"; then
                echo >&2 "error fetching '$my_installer_url'"
                exit 1
            fi
        fi

        (
            cd "${b_install_tmpdir}"
            sh "${b_package}-install.sh"
        )

        rm -rf "${b_install_tmpdir}"

    }

    show_path_updates() {

        if test -z "${_WEBI_CHILD}"; then
            if test -f "$_webi_tmp/.PATH.env"; then
                my_paths=$(sort -u < "$_webi_tmp/.PATH.env")
                if test -n "$my_paths"; then
                    printf 'PATH.env updated with:\n'
                    printf "%s\n" "$my_paths"
                    printf '\n'
                    printf "\e[1m\e[35mTO FINISH\e[0m: copy, paste & run the following command:\n"
                    printf "\n"
                    printf "        \e[1m\e[32msource ~/.config/envman/PATH.env\e[0m\n"
                    printf "        (newly opened terminal windows will update automatically)\n"
                fi
                rm -f "$_webi_tmp/.PATH.env"
            fi
        fi

    }

    fn_checksum() {
        cmd_shasum='sha1sum'
        if command -v shasum > /dev/null; then
            cmd_shasum='shasum'
        fi
        $cmd_shasum "${0}" | cut -d' ' -f1 | cut -c 1-8
    }

    version() {
        my_checksum="$(
            fn_checksum
        )"
        my_version=v1.2.0
        printf "\e[35mwebi\e[32m %s\e[0m Copyright 2020+ AJ ONeal\n" "${my_version} (${my_checksum})"
        printf "    \e[36mhttps://webinstall.dev/webi\e[0m\n"
    }

    # show help if no params given or help flags are used
    usage() {
        echo ""
        version
        echo ""

        printf "\e[1mSUMMARY\e[0m\n"
        echo "    Webi is the best way to install the modern developer tools you love."
        echo "    It's fast, easy-to-remember, and conflict free."
        echo ""
        printf "\e[1mUSAGE\e[0m\n"
        echo "    webi <thing1>[@version] [thing2] ..."
        echo ""
        printf "\e[1mUNINSTALL\e[0m\n"
        echo "    Almost everything that is installed with webi is scoped to"
        echo "    ~/.local/opt/<thing1>, so you can remove it like so:"
        echo ""
        echo "    rm -rf ~/.local/opt/<thing1>"
        echo "    rm -f ~/.local/bin/<thing1>"
        echo ""
        echo "    Some packages have special uninstall instructions, check"
        echo "    https://webinstall.dev/<thing1> to be sure."
        echo ""
        printf "\e[1mOPTIONS\e[0m\n"
        echo "    Generic Program Information"
        echo "        --help Output a usage message and exit."
        echo ""
        echo "        -V, --version"
        echo "               Output the version number of webi and exit."
        echo ""
        echo "    Helper Utilities"
        echo "        --list Show everything webi has to offer."
        echo ""
        echo "        --info <package>"
        echo "               Show various links and example release."
        echo ""
        printf "\e[1mFAQ\e[0m\n"
        printf "    See \e[34mhttps://webinstall.dev/faq\e[0m\n"
        echo ""
        printf "\e[1mALWAYS REMEMBER\e[0m\n"
        echo "    Friends don't let friends use brew for simple, modern tools that don't need it."
        echo "    (and certainly not apt either **shudder**)"
        echo ""
    }

    if [ $# -eq 0 ] || echo "$1" | grep -q -E '^(-V|--version|version)$'; then
        version
        exit 0
    fi

    if echo "$1" | grep -q -E '^(-h|--help|help)$'; then
        usage "$@"
        exit 0
    fi

    if echo "$1" | grep -q -E '^(-l|--list|list)$'; then
        echo >&2 "[warn] the format of --list output may change"

        # because we don't have sitemap.xml for dev sites yet
        my_host="https://webinstall.dev"
        my_len="${#my_host}"

        # 6 because the field will looks like "loc>WEBI_HOST/PKG_NAME"
        # and the count is 1-indexed
        my_count="$((my_len + 6))"

        curl -fsS "${my_host}/sitemap.xml" |
            grep -F "${my_host}" |
            cut -d'<' -f2 |
            cut -c "${my_count}"-

        exit 0
    fi

    if echo "${1}" | grep -q -E '^(--info|info)$'; then
        if test -z "${2}"; then
            echo >&2 "Usage: webi --info <package>"
            exit 1
        fi

        echo >&2 "[warn] the output of --info is completely half-baked and will change"
        my_pkg="${2}"
        # TODO need a way to check that it exists at all (readme, win, lin)
        echo ""
        echo "    Cheat Sheet: ${WEBI_HOST}/${my_pkg}"
        echo "          POSIX: curl -sS ${WEBI_HOST}/${my_pkg} | sh"
        echo "        Windows: curl.exe -A MS ${WEBI_HOST}/${my_pkg} | powershell"
        echo "Releases (JSON): ${WEBI_HOST}/api/releases/${my_pkg}.json"
        echo " Releases (tsv): ${WEBI_HOST}/api/releases/${my_pkg}.tab"
        echo " (query params):     ?channel=stable&limit=10"
        echo "                     &os=${my_os}&arch=${my_arch}"
        echo " Install Script: ${WEBI_HOST}/api/installers/${my_pkg}.sh?formats=tar,zip,xz,git,dmg,pkg"
        echo "  Static Assets: ${WEBI_HOST}/packages/${my_pkg}/README.md"
        echo ""

        # TODO os=linux,macos,windows (limit to tagged releases)
        my_releases="$(
            curl -fsS "${WEBI_HOST}/api/releases/${my_pkg}.json?channel=stable&limit=1&pretty=true"
        )"

        if printf '%s\n' "${my_releases}" | grep -q "error"; then
            my_releases_beta="$(
                curl -fsS "${WEBI_HOST}/api/releases/${my_pkg}.json?&limit=1&pretty=true"
            )"
            if printf '%s\n' "${my_releases_beta}" | grep -q "error"; then
                echo >&2 "'${my_pkg}' is a special case that does not have releases"
            else
                echo >&2 "ERROR no stable releases for '${my_pkg}'!"
            fi
            exit 0
        fi

        echo >&2 "Stable '${my_pkg}' releases:"
        if command -v jq > /dev/null; then
            printf '%s\n' "${my_releases}" |
                jq
        else
            printf '%s\n' "${my_releases}"
        fi

        exit 0
    fi

    for pkgname in "$@"; do
        webinstall "$pkgname"
        export WEBI_WELCOME='shown'
    done

    show_path_updates

}

__webi_main "$@"
