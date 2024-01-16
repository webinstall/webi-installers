#!/bin/sh

set -e
set -u
#set -x

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
    set -e

    my_uname_o="$(uname -o 2> /dev/null || echo '')"
    my_libc=''
    if ldd /bin/ls 2> /dev/null | grep -q 'musl' 2> /dev/null; then
        my_libc='musl'
    elif echo "${my_uname_o}" | grep -q 'GNU' || uname -s | grep -q 'Linux'; then
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
        a_filepath="${1}"

        if command -v sha1sum > /dev/null; then
            sha1sum "${a_filepath}" | cut -d' ' -f1 | cut -c 1-8
            return 0
        fi

        if command -v shasum > /dev/null; then
            shasum "${a_filepath}" | cut -d' ' -f1 | cut -c 1-8
            return 0
        fi

        if command -v sha1 > /dev/null; then
            sha1 "${a_filepath}" | cut -d'=' -f2 | cut -c 2-9
            return 0
        fi

        echo >&2 "    warn: no sha1 sum program"
        date '+%F %H:%M'
    }

    version() {
        my_checksum="$(
            fn_checksum "${0}"
        )"
        my_version=v1.2.8
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
        echo "        --init Register command line completions with shell"
        echo ""
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

    if echo "$1" | grep -q -E '^(--list|list)$'; then
        webi_list
        exit 0
    fi

    if echo "${1}" | grep -q -E '^(--info|info)$'; then
        webi_info "$@"
        exit 0
    fi

    if echo "$1" | grep -q -E '^(--init|init)$'; then
        webi_shell_init "$@"
        exit 0
    fi

    for pkgname in "$@"; do
        webinstall "$pkgname"
        export WEBI_WELCOME='shown'
    done

    show_path_updates

}

webi_shell_init() { (
    a_shell="${2:-}"

    fn_shell_integrate_bash ""
    fn_shell_integrate_zsh ""
    fn_shell_integrate_fish ""

    # update completions now
    webi_list > /dev/null

    if [ $# -eq 1 ]; then
        exit 0
    fi

    case "${a_shell}" in
        bash)
            fn_shell_integrate_bash "force"
            fn_shell_init_bash
            ;;
        zsh)
            fn_shell_integrate_zsh "force"
            fn_shell_init_zsh
            ;;
        fish)
            fn_shell_integrate_fish "force"
            fn_shell_init_fish
            ;;
        *)
            echo >&2 "Unsupported shell: $2"
            exit 1
            ;;
    esac
) }

fn_shell_integrate_bash() { (
    a_force="${1}"
    if test -z "${a_force}"; then
        if ! command -v bash > /dev/null; then
            return 0
        fi

        if ! test -e ~/.bashrc && ! test -e ~/.bash_history; then
            return 0
        fi
    fi

    touch -a ~/.bashrc
    if grep -q 'webi --init' ~/.bashrc; then
        return 0
    fi

    echo >&2 "    Edit ~/.bashrc to add 'eval \"\$(webi --init bash)\"'"
    # shellcheck disable=SC2016
    {
        echo ''
        echo '# Generated by Webi. Do not edit.'
        echo 'eval "$(webi --init bash)"'
    } >> ~/.bashrc
); }

# shellcheck disable=SC2016
fn_shell_init_bash() { (
    echo '_webi() {'
    echo '    COMPREPLY=()'
    echo '    local cur="${COMP_WORDS[COMP_CWORD]}"'
    echo '    if [ "$COMP_CWORD" -eq 1 ]; then'
    echo '        local completions=$(webi --list | cut -d" " -f1)'
    echo '        COMPREPLY=( $(compgen -W "$completions" -- "$cur") )'
    echo '    fi'
    echo '}'
    echo ''
    echo 'complete -F _webi webi'
); }

fn_shell_integrate_zsh() { (
    a_force="${1}"
    if test -z "${a_force}"; then
        if ! command -v zsh > /dev/null; then
            return 0
        fi

        if ! test -e ~/.zshrc &&
            ! test -e ~/.zsh_sessions &&
            ! test -e ~/.zsh_history; then
            return 0
        fi
    fi

    touch -a ~/.zshrc
    if grep -q 'webi --init' ~/.zshrc; then
        return 0
    fi

    echo >&2 "    Edit ~/.zshrc to add 'eval \"\$(webi --init zsh)\"'"
    # shellcheck disable=SC2016
    {
        echo ''
        echo '# Generated by Webi. Do not edit.'
        echo 'eval "$(webi --init zsh)"'
    } >> ~/.zshrc
); }

# shellcheck disable=SC2016
fn_shell_init_zsh() { (
    echo '_webi() {'
    echo '    local -a list completions'
    echo '    list=$(webi --list | cut -d" " -f1)'
    echo '    completions=(${(f)list})'
    echo '    _describe -t commands "command" completions && ret=0'
    echo '}'
    echo ''
    echo 'autoload -Uz compinit && compinit'
    echo 'compdef _webi webi'
); }

fn_shell_integrate_fish() { (
    a_force="${1}"
    if test -z "${a_force}"; then
        if ! command -v fish > /dev/null; then
            return 0
        fi
    fi

    mkdir -p ~/.config/fish
    touch -a ~/.config/fish/config.fish
    if grep -q 'webi --init' ~/.config/fish/config.fish; then
        return 0
    fi

    echo >&2 "    Edit ~/.config/fish/config.fish to add 'webi --init fish | source'"
    # shellcheck disable=SC2016
    {
        echo ''
        echo '# Generated by Webi. Do not edit.'
        echo 'webi --init fish | source'
    } >> ~/.config/fish/config.fish
); }

# shellcheck disable=SC2016
fn_shell_init_fish() { (
    echo 'function __fish_webi_needs_command'
    echo '    set cmd (commandline -opc)'
    echo '    if [ (count $cmd) -eq 1 -a $cmd[1] = "webi" ]'
    echo '        return 0'
    echo '    end'
    echo '    return 1'
    echo 'end'
    echo ''
    echo 'set completions (webi --list | cut -d" " -f1)'
    echo 'complete -f -c webi -n __fish_webi_needs_command -a "$completions"'
); }

webi_list() { (
    # make sure there's always a cache dir and timestamp file
    mkdir -p ~/.local/share/webi/var/

    if ! test -r ~/.local/share/webi/var/list.txt; then
        echo '0' > ~/.local/share/webi/var/last_update
    elif ! test -r ~/.local/share/webi/var/last_update; then
        echo '0' > ~/.local/share/webi/var/last_update
    fi

    # compare the timestamp in the timestamp file to now
    # (in seconds since unix epoch)
    my_stale_age=600
    my_expire_age=900
    my_now="$(date -u '+%s')"
    my_then="$(cat ~/.local/share/webi/var/last_update)"
    my_diff=$((my_now - my_then))

    # show when the cache will update
    my_stales_in=$((my_stale_age - my_diff))
    my_expires_in=$((my_expire_age - my_diff))

    # update if it's been longer than the staletime
    if test "${my_stales_in}" -lt "0"; then
        if test "${my_expires_in}" -lt "0"; then
            fn_list_uncached
        else
            fn_list_uncached &
        fi
    fi

    # give back the list
    cat ~/.local/share/webi/var/list.txt
); }

fn_list_uncached() { (
    # because we don't have sitemap.xml for dev sites yet
    my_host="https://webinstall.dev"

    my_len="${#my_host}"
    # 6 because the field will looks like "loc>WEBI_HOST/PKG_NAME"
    # and the count is 1-indexed
    my_count="$((my_len + 6))"

    my_now="$(date -u '+%s')"
    echo "${my_now}" > ~/.local/share/webi/var/last_update

    my_tmp="$(mktemp)"
    {
        echo "help"
        echo "--help"
        echo "version"
        echo "-V"
        echo "--version"
        echo "--init" # <shell>
        echo "--list"
        echo "--info" # <package>
    } > "${my_tmp}"
    curl -fsS "${my_host}/sitemap.xml" |
        grep -F "${my_host}" |
        cut -d'<' -f2 |
        cut -c "${my_count}"- >> "${my_tmp}"
    mv "${my_tmp}" ~/.local/share/webi/var/list.txt

    my_now="$(date -u '+%s')"
    echo "${my_now}" > ~/.local/share/webi/var/last_update
); }

webi_info() { (
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
); }

__webi_main "$@"
