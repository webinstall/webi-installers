#!/bin/sh

# "This is too simple" you say! "Where is the magic!?" you ask.
# There is no magic!
# The custom functions for node are here.
# The generic functions - version checks, download, extract, etc - are here:
#   - https://github.com/webinstall/packages/branches/master/_webi/template.sh

set -e
set -u

pkg_cmd_name="node"
#WEBI_SINGLE=""

pkg_get_current_version() {
    # 'node --version' has output in this format:
    #       v12.8.0
    # This trims it down to just the version number:
    #       12.8.0
    node --version 2> /dev/null |
        head -n 1 |
        cut -d' ' -f1 |
        sed 's:^v::'
}

pkg_install() {
    # mkdir -p $HOME/.local/opt
    mkdir -p "$(dirname "$pkg_src")"

    # mv ./node* "$HOME/.local/opt/node-v14.4.0"
    mv ./"$pkg_cmd_name"* "$pkg_src"
}

pkg_link() {
    # rm -f "$HOME/.local/opt/node"
    rm -f "$pkg_dst"

    # ln -s "$HOME/.local/opt/node-v14.4.0" "$HOME/.local/opt/node"
    ln -s "$pkg_src" "$pkg_dst"
}

pkg_done_message() {
    b_dst="$(fn_sub_home "${pkg_dst}")"
    echo ""
    echo "    Installed $(t_pkg 'node') and $(t_pkg 'npm') at $(t_path "${b_dst}/")"

    if command -v apk > /dev/null; then
        if ! apk info | grep -F 'libstdc++' > /dev/null; then
            echo ""
            echo "    $(t_pkg 'WARNING'): $(t_pkg 'libstdc++') is required for $(t_pkg 'node'), but not installed" >&2
            if command -v sudo > /dev/null; then
                cmd_sudo='sudo '
            fi
            _install_webi_essentials_apk "${cmd_sudo}" 'libstdc++'
        fi
    fi
}

_install_webi_essentials_apk() { (
    cmd_sudo="${1}"
    b_pkgs="${2}"

    #echo "    $(t_dim 'Running') $(t_cmd "${cmd_sudo}apk add --no-cache")"
    fn_polite_sudo "${cmd_sudo}" "    $(t_cmd "apk add --no-cache ${b_pkgs}")"
    # shellcheck disable=SC2086
    ${cmd_sudo} apk add --no-cache ${b_pkgs}
); }

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
    printf '%s\n' "$(t_attn 'Use sudo to run the following? [Y/n] ')"
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
