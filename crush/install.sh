#!/bin/sh
# shellcheck disable=SC2034

set -e
set -u

__init_crush() {

    ##################
    # Install crush #
    ##################

    # Every package should define these 6 variables
    pkg_cmd_name="crush"

    pkg_dst_cmd="$HOME/.local/bin/crush"
    pkg_dst="$pkg_dst_cmd"

    pkg_src_cmd="$HOME/.local/opt/crush-v$WEBI_VERSION/bin/crush"
    pkg_src_dir="$HOME/.local/opt/crush-v$WEBI_VERSION"
    pkg_src="$pkg_src_cmd"

    pkg_install() {
        # $HOME/.local/opt/crush-v0.50.1/bin
        mkdir -p "$(dirname "$pkg_src_cmd")"

        # (goreleaser archive: crush_VERSION_OS_arch/crush)
        mv ./crush_*/"$pkg_cmd_name" "$pkg_src_cmd"
        chmod a+x "$pkg_src_cmd"

        # Install manpage if present
        # (archive contains crush_VERSION_OS_arch/manpages/crush.1.gz)
        if test -f ./crush_*/manpages/crush.1.gz; then
            mkdir -p "$HOME/.local/share/man/man1"
            mv ./crush_*/manpages/crush.1.gz "$HOME/.local/share/man/man1/"
        fi

        # Install shell completions if present
        # (archive contains crush_VERSION_OS_arch/completions/{crush.bash,crush.fish,crush.zsh})
        if test -f ./crush_*/completions/crush.bash; then
            mkdir -p "$HOME/.local/share/bash-completion/completions"
            mv ./crush_*/completions/crush.bash "$HOME/.local/share/bash-completion/completions/crush"
        fi

        if test -f ./crush_*/completions/crush.zsh; then
            mkdir -p "$HOME/.local/share/zsh/site-functions"
            mv ./crush_*/completions/crush.zsh "$HOME/.local/share/zsh/site-functions/_crush"
        fi

        if test -f ./crush_*/completions/crush.fish; then
            mkdir -p "$HOME/.config/fish/completions"
            mv ./crush_*/completions/crush.fish "$HOME/.config/fish/completions/crush.fish"
        fi
    }

    pkg_get_current_version() {
        # 'crush --version' outputs just the version number:
        #       0.50.1
        crush --version 2> /dev/null | head -n 1 | sed 's:^v::'
    }

    pkg_done_message() {
        echo "Installed 'crush' v${WEBI_VERSION} with shell completions and manpage"
    }

}

__init_crush
