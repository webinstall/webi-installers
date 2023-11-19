#!/bin/sh
#<pre>

############################################################
# <h1>Cheat Sheet at CHEATSHEET_URL</h1>
# <meta http-equiv="refresh" content="3; URL='CHEATSHEET_URL'" />
############################################################

export WEBI_PKG=webi
export WEBI_HOST=https://webinstall.dev
export WEBI_CHECKSUM=06a7fb9f

#########################################
#                                       #
# Display Debug Info in Case of Failure #
#                                       #
#########################################

fn_show_welcome() { (
    echo ""
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
# Install or Update Webi and Install Package #
#                                            #
##############################################

webi_bootstrap() { (
    a_path="${1}"

    echo ""
    echo "$(t_task 'Bootstrapping') $(t_pkg 'Webi')"

    b_path_rel="$(fn_sub_home "${a_path}")"
    b_checksum=""
    if test -r "${a_path}"; then
        b_checksum="$(fn_checksum "${a_path}")"
    fi
    if test "$b_checksum" = "${WEBI_CHECKSUM}"; then
        echo "    $(t_dim 'Found') $(t_path "${b_path_rel}")"
        sleep 0.1
        return 0
    fi

    b_webi_file_url="${WEBI_HOST}/packages/webi/webi.sh"
    b_tmp=''
    if test -r "${a_path}"; then
        b_ts="$(date -u '+%s')"
        b_tmp="${a_path}.${b_ts}.bak"
        mv "${a_path}" "${b_tmp}"
        echo "    Updating $(t_path "${b_path_rel}")"
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

    WEBI_TTY="${WEBI_TTY:-}"
    if test -z "${WEBI_TTY}"; then
        if fn_detect_tty; then
            WEBI_TTY="tty"
        fi
        export WEBI_TTY
    fi

    if test -z "${WEBI_WELCOME:-}"; then
        fn_show_welcome
    fi
    export WEBI_WELCOME='shown'

    # note: we may support custom locations in the future
    export WEBI_HOME="${HOME}/.local"
    b_home="$(fn_sub_home "${WEBI_HOME}")"
    b_webi_path="${WEBI_HOME}/bin/webi"
    b_webi_path_rel="${b_home}/bin/webi"

    WEBI_CURRENT="${WEBI_CURRENT:-}"
    if test "${WEBI_CURRENT}" != "${WEBI_CHECKSUM}"; then
        webi_bootstrap "${b_webi_path}"
        export WEBI_CURRENT="${WEBI_CHECKSUM}"
    fi

    echo "    Running $(t_cmd "${b_webi_path_rel} ${WEBI_PKG}")"
    echo ""

    "${b_webi_path}" "${WEBI_PKG}"
); }

main
