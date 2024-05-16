#!/bin/sh
set -e
set -u

__init_pwsh() {

    pkg_cmd_name="pwsh"

    # note: no ./bin prefix
    pkg_src_cmd="$HOME/.local/opt/pwsh-v$WEBI_VERSION/pwsh"
    pkg_src_dir="$HOME/.local/opt/pwsh-v$WEBI_VERSION/"
    pkg_src="$HOME/.local/opt/pwsh-v$WEBI_VERSION/"

    pkg_dst_cmd="$HOME/.local/opt/pwsh/pwsh"
    pkg_dst_dir="$HOME/.local/opt/pwsh"
    pkg_dst="$HOME/.local/opt/pwsh"

    pkg_get_current_version() {
        # 'pwsh --version' has output in this format:
        #       PowerShell 7.0.2
        # This trims it down to just the version number:
        #       7.0.2
        pwsh --version 2> /dev/null | head -n 1 | cut -d' ' -f2
    }

    pkg_install() {
        # mv ./* "$HOME/.local/opt/pwsh-v7.0.2"
        mkdir -p "$pkg_src"
        mv ./* "$pkg_src"

        # symlink pwsh as powershell
        (
            cd "$pkg_src" > /dev/null
            rm -rf powershell
            ln -s pwsh powershell
        )
    }

    pkg_link() {
        # rm -f "$HOME/.local/opt/pwsh"
        rm -rf "$pkg_dst"

        # ln -s "$HOME/.local/opt/pwsh-v7.0.2" "$HOME/.local/opt/pwsh"
        ln -s "$pkg_src" "$pkg_dst"
    }

    pkg_done_message() {
        # We print the version here to ensure the install completed without
        # errors - no missing libraries, not incompatible arch, etc
        echo ""
        "$pkg_dst_cmd" -V
    }
}

__init_pwsh
