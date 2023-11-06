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

# shellcheck disable=SC2005
fn_show_welcome() { (
    echo ""
    printf "%s %s\n" \
        "$(t_strong 'Welcome to') $(t_stronger 'Webi')$(t_strong '!')" \
        "$(t_dim "- Modern tools, instant installs.")"
    echo "We expect your experience to be $(t_em 'absolutely perfect')!"
    echo ""
    echo "    $(t_yellow 'Have a problem?') Please $(t_em 'let us know'):"
    echo "        $(t_url 'https://github.com/webinstall/webi-installers/issues')"
    echo "        $(t_dim "(your system is $(t_yellow "$(uname -s)")/$(t_yellow "$(uname -m)") with $(t_yellow "$(fn_get_libc)") & $(t_yellow "$(fn_get_http)"))")"
    echo ""
    echo "    $(t_yellow 'Love it?') Star it!"
    echo "        $(t_url 'https://github.com/webinstall/webi-installers')"

    sleep 0.2
); }

t_strong() { (printf '\e[36m%s\e[39m' "${1}"); }
t_stronger() { (printf '\e[1m\e[32m%s\e[39m\e[22m' "${1}"); }
t_url() { (printf '\e[2m%s\e[22m' "${1}"); }
t_path() { (printf '\e[2m\e[32m%s\e[39m\e[22m' "${1}"); }
t_cmd() { (printf '\e[2m\e[35m%s\e[39m\e[22m' "${1}"); }
t_err() { (printf '\e[31m%s\e[39m' "${1}"); }

t_bold() { (printf '\e[1m%s\e[22m' "${1}"); }
t_dim() { (printf '\e[2m%s\e[22m' "${1}"); }
t_em() { (printf '\e[3m%s\e[23m' "${1}"); }
t_under() { (printf '\e[4m%s\e[24m' "${1}"); }
t_green() { (printf '\e[32m%s\e[39m' "${1}"); }
t_yellow() { (printf '\e[33m%s\e[39m' "${1}"); }
t_magenta() { (printf '\e[35m%s\e[39m' "${1}"); }
t_cyan() { (printf '\e[36m%s\e[39m' "${1}"); }

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

fn_get_http() { (
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
    if fn_is_interactive; then
        cmd_wget="wget -q --show-progress --user-agent"
    fi

    b_triple_ua="$(fn_get_target_triple_user_agent)"
    b_agent="webi/wget ${b_triple_ua}"
    if command -v curl > /dev/null; then
        b_agent="webi/wget+curl ${b_triple_ua}"
    fi

    if ! $cmd_wget "${b_agent}" -c "${a_url}" -O "${a_path}"; then
        echo >&2 "    $(t_err "failed to download (wget)") '$(t_url "${a_url}")'"
        return 1
    fi
); }

fn_curl() { (
    # Doc:
    #     Downloads the file at the given url to the given path
    a_url="${1}"
    a_path="${2}"

    cmd_curl="curl --fail-with-body -sSL -#"
    if fn_is_interactive; then
        cmd_curl="curl --fail-with-body sSL"
    fi

    b_triple_ua="$(fn_get_target_triple_user_agent)"
    b_agent="webi/curl ${b_triple_ua}"
    if command -v wget > /dev/null; then
        b_agent="webi/curl+wget ${b_triple_ua}"
    fi

    if ! $cmd_curl -A "${b_agent}" "${a_url}" -o "${a_path}"; then
        echo >&2 "    $(t_err "failed to download (curl)") '$(t_url "${a_url}")'"
        return 1
    fi
); }

fn_is_interactive() {
    # Ex:
    #     himBH
    #     hBc
    case $- in
        *i*) return 0 ;;
        *) return 1 ;;
    esac
}

fn_get_target_triple_user_agent() { (
    # Ex:
    #     x86_64/unknown Linux/5.15.107-2-pve gnu
    #     arm64/unknown Darwin/22.6.0 libc
    echo "$(uname -m)/unknown $(uname -s)/$(uname -r) $(fn_get_libc)"
); }

fn_download_to_path() { (
    a_url="${1}"
    a_path="${2}"

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

webi_upgrade() { (
    a_path="${1}"

    echo ""
    echo "$(t_strong 'Bootstrapping') $(t_stronger 'Webi')"

    b_path_rel="$(fn_sub_home "${a_path}")"
    b_checksum=""
    if test -r "${a_path}"; then
        echo "    $(t_dim 'Found') $(t_path "${b_path_rel}")"
        b_checksum="$(fn_checksum "${a_path}")"
    fi
    if test "$b_checksum" == "${WEBI_CHECKSUM}"; then
        sleep 0.1
        return 0
    fi

    b_webi_file_url="${WEBI_HOST}/packages/webi/webi.sh"
    if test -r "${a_path}"; then
        echo "    Updating $(t_path "${b_path_rel}")"
    fi
    echo "    Downloading $(t_url "${b_webi_file_url}")"
    echo "        to $(t_path "${b_path_rel}")"
    fn_download_to_path "${b_webi_file_url}" "${a_path}"
    chmod u+x "${a_path}"
); }

fn_checksum() {
    a_filepath="${1}"

    cmd_shasum='sha1sum'
    if command -v shasum > /dev/null; then
        cmd_shasum='shasum'
    fi

    $cmd_shasum "${a_filepath}" | cut -d' ' -f1 | cut -c 1-8
}

fn_sub_home() { (
    my_rel=${HOME}
    my_abs=${1}
    echo "${my_abs}" | sed "s:^${my_rel}:~:"
); }

main() { (
    fn_show_welcome
    export WEBI_WELCOME=true

    # note: we may support custom locations in the future
    export WEBI_HOME="${HOME}/.local"
    b_home="$(fn_sub_home "${WEBI_HOME}")"
    b_webi_path="${WEBI_HOME}/bin/webi"
    b_webi_path_rel="${b_home}/bin/webi"
    webi_upgrade "${b_webi_path}"

    echo ""
    echo "$(t_strong 'Installing') $(t_stronger "${WEBI_PKG}") $(t_strong '...')"
    echo "    Running $(t_cmd "${b_webi_path_rel} ${WEBI_PKG}")"
    "${b_webi_path}" "${WEBI_PKG}"
); }

set -e
set -u
main
