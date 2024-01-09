#!/bin/sh
set -e
set -u

fn_install_webi_essentials_macos() { (
    # streamline the output to be pretty
    b_pkgs="$(
        fn_check_pkg 'curl'
        fn_check_pkg '/Library/Developer/CommandLineTools/usr/bin/git' 'git'
        if test "$(uname -m)" = 'arm64'; then
            fn_check_pkg '/Library/Apple/usr/libexec/oah/libRosettaRuntime' 'rosetta'
        fi
        fn_check_pkg 'tar'
        # no wget because it requires brew
        #fn_check_pkg 'wget'
        fn_check_pkg 'xz'
        fn_check_pkg 'zip'
    )"
    echo >&2 ""

    #curl - built-in
    # git
    if ! xcode-select -p > /dev/null 2> /dev/null; then
        cmd_xcode_cli_tools_install="xcode-select --install"
        echo "    Running $(t_cmd "${cmd_xcode_cli_tools_install}")"
        $cmd_xcode_cli_tools_install 2> /dev/null
        echo ""
        echo ">>> $(t_attn 'ACTION REQUIRED') <<<"
        echo ""
        echo "        $(t_attn "Click") '$(t_bold 'Install')' $(t_attn "in the pop-up")"
        echo "        (it may appear $(t_em 'under') this window)"
        echo ""
        echo "^^^ $(t_attn 'ACTION REQUIRED') ^^^"
        echo ""
        echo "    waiting $(t_em 'for you') to finish installing Command Line Developer Tools ..."
        while ! test -x /Library/Developer/CommandLineTools/usr/bin/git; do
            sleep 0.25
        done
        echo "    $(t_info 'OK')"
        echo ""
        sleep 1
    fi
    # rosetta
    if test "$(uname -m)" = 'arm64'; then
        # Also pkgutil --pkg-info com.apple.pkg.RosettaUpdateAuto
        # See <https://apple.stackexchange.com/q/427970/27465>
        cmd_install_rosetta="softwareupdate --install-rosetta --agree-to-license"
        if ! arch -arch x86_64 uname -m > /dev/null 2>&1; then
            echo "    Running $(t_cmd "${cmd_install_rosetta}")"
            $cmd_install_rosetta
        fi
    fi
    #tar - built-in
    #wget - skip
    #xz
    if ! command -v xz > /dev/null; then
        echo "    Running $(t_cmd "webi xz")"
        ~/.local/bin/webi xz
    fi
    #zip - built-in

    # This should NEVER fail, but... Sanity check :)
    {
        b_pkgs_builtin="$(
            fn_check_pkg 'curl'
            fn_check_pkg 'tar'
            fn_check_pkg 'zip'
        )"
    } 2> /dev/null
    if test -n "${b_pkgs_builtin}"; then
        echo ""
        echo "error: expected these to be macOS built-ins:"
        echo "    ${b_pkgs}"
        echo ""
        exit 1
    fi

    echo "    $(t_dim 'OK')"
); }

fn_check_pkg() { (
    a_pkg="${1}"
    a_pkgname="${2:-$a_pkg}"

    printf >&2 '    %s %s %s' \
        "$(t_dim "Checking for")" \
        "$(t_pkg "${a_pkgname}")" \
        "$(t_dim "...")"

    if command -v "${a_pkg}" > /dev/null; then
        echo >&2 " $(t_dim 'OK')"
        return 0
    fi

    echo >&2 ' missing'
    echo "${a_pkg}"
); }

###########
# mainish #
###########

fn_polite_sudo() { (
    a_sudo="${1}"
    a_cmds="${2}"

    # no sudo needed, so don't ask
    if test -z "${a_sudo}"; then
        return 0
    fi

    # this is scripted, not user-interactive, continue
    if test -z "${WEBI_TTY}"; then
        return 0
    fi

    # this is user interactive, ask the user,defaulting to yes
    echo ""
    #shellcheck disable=SC2005 # echo for newline
    echo "$(t_attn 'Use sudo for the following? [Y/n]')"
    echo "${a_cmds}"
    read -r b_yes < /dev/tty

    b_yes="$(
        echo "${b_yes}" |
            tr '[:upper:]' '[:lower:]' |
            tr -d '[:space:]'
    )"
    if test -z "${b_yes}" || test "${b_yes}" = "y" || test "${b_yes}" = "yes"; then
        return 0
    fi
    echo "    aborted"
    return 1
); }

_install_webi_essentials() { (
    if test "$(uname -s)" = 'Darwin'; then
        fn_install_webi_essentials_macos
        return 0
    fi

    b_pkgs="$(
        fn_check_pkg 'curl'
        fn_check_pkg 'git'
        fn_check_pkg 'tar'
        fn_check_pkg 'wget'
        fn_check_pkg 'xz'
        fn_check_pkg 'zip'
    )"
    b_pkgs="$(echo "${b_pkgs}" | tr '\n' ' ' | tr -s ' ')"
    if test "${b_pkgs}" = " "; then
        b_pkgs=''
    fi

    if test -z "${b_pkgs}"; then
        echo "    $(t_dim 'OK')"
        return 0
    fi

    cmd_sudo=''
    if test "$(id -u)" != "0"; then
        echo "    $(t_dim 'Checking for sudo ...')"
        if command -v sudo > /dev/null; then
            cmd_sudo='sudo '
        else
            if test "${b_pkgs}" = "xz"; then
                _install_webi_essentials_webi "${cmd_sudo}" "${b_pkgs}"
                echo "    $(t_dim 'OK')"
                return 0
            fi

            echo ""
            echo ">>> $(t_warn 'WARNING') <<<"
            echo ""
            echo "    You are not the 'root' user and there is no 'sudo'."
            echo "    (We'll try anyway but... this isn't going to work.)"
            echo ""
            echo "^^^ $(t_warn 'WARNING') ^^^"
            echo ""
        fi
    fi

    printf '%s' "    $(t_dim 'Checking for apt/apk ...')"
    if command -v apt > /dev/null; then
        echo " $(t_pkg 'apt')"
        _install_webi_essentials_apt "${cmd_sudo}" "${b_pkgs}"
        echo "    $(t_dim 'OK')"
        return 0
    fi

    if command -v apk > /dev/null; then
        echo " $(t_pkg 'apk')"
        _install_webi_essentials_apk "${cmd_sudo}" "${b_pkgs}"
        echo "    $(t_dim 'OK')"
        return 0
    fi

    echo " $(t_dim 'none')"
    _install_webi_essentials_webi "${cmd_sudo}" "${b_pkgs}"
    echo "    $(t_dim 'OK')"
); }

_install_webi_essentials_apt() { (
    cmd_sudo="${1}"
    b_pkgs="${2}"
    b_pkgs="$(echo "${b_pkgs}" | sed 's/xz/xz-utils/g')"

    b_cmds="$(
        printf '    %s\n    %s' \
            "$(t_cmd 'apt update')" \
            "$(t_cmd "apt install -y ${b_pkgs}")"
    )"
    fn_polite_sudo "${cmd_sudo}" "${b_cmds}"

    echo "    $(t_dim 'Running') $(t_cmd "${cmd_sudo}apt update")"
    ${cmd_sudo} apt update

    echo "    $(t_dim 'Running') $(t_cmd "${cmd_sudo}apt install -y ${b_pkgs}")"
    # shellcheck disable=SC2086
    ${cmd_sudo} apt install -y ${b_pkgs}
); }

_install_webi_essentials_apk() { (
    cmd_sudo="${1}"
    b_pkgs="${2}"

    echo "    $(t_dim 'Running') $(t_cmd "${cmd_sudo}apk add --no-cache")"
    fn_polite_sudo "${cmd_sudo}" "    $(t_cmd "apk add --no-cache ${b_pkgs}")"
    # shellcheck disable=SC2086
    ${cmd_sudo} apk add --no-cache ${b_pkgs}
); }

_install_webi_essentials_webi() { (
    cmd_sudo="${1}"
    b_pkgs="${2}"

    if test "${b_pkgs}" = 'xz'; then
        ~/.local/bin/webi xz
        return 0
    fi

    if echo "${b_pkgs}" | grep -q xz; then
        ~/.local/bin/webi xz
        b_pkgs="$(echo "${b_pkgs}" | sed 's/\sxz\s/ /')"
    fi

    echo ""
    echo "error: unknown operating system:"
    echo "    $(uname -srm)"
    if test -r /etc/issue; then
        echo "    $(cat /etc/issue)"
    fi
    echo ""
    echo "$(t_err 'could not install'): $(t_warn "${b_pkgs}")"
    echo ""
    return 1
); }

_install_webi_essentials
