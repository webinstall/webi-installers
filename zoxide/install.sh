#!/bin/sh

__init_zoxide() {
    set -e
    set -u

    ##################
    # Install zoxide #
    ##################

    # Every package should define these 6 variables
    pkg_cmd_name="zoxide"

    pkg_dst_cmd="$HOME/.local/bin/zoxide"
    pkg_dst="$pkg_dst_cmd"

    pkg_src_cmd="$HOME/.local/opt/zoxide-v$WEBI_VERSION/bin/zoxide"
    pkg_src_dir="$HOME/.local/opt/zoxide-v$WEBI_VERSION"
    pkg_src="$pkg_src_cmd"

    # pkg_install must be defined by every package
    pkg_install() {
        # mkdir -p "~/.local/opt/zoxide-v0.99.9/bin"
        mkdir -p "$(dirname "$pkg_src_cmd")"

        # mv ./zoxide "~/.local/opt/zoxide-v0.99.9/bin/zoxide"
        mv ./zoxide "$pkg_src_cmd"

        # install completions if present
        if test -d ./completions; then
            mkdir -p "$pkg_src_dir/share/bash-completion/completions"
            mkdir -p "$pkg_src_dir/share/fish/vendor_completions.d"
            mkdir -p "$pkg_src_dir/share/zsh/site-functions"
            mv ./completions/zoxide.bash "$pkg_src_dir/share/bash-completion/completions/zoxide" 2>/dev/null || true
            mv ./completions/zoxide.fish "$pkg_src_dir/share/fish/vendor_completions.d/zoxide.fish" 2>/dev/null || true
            mv ./completions/_zoxide "$pkg_src_dir/share/zsh/site-functions/_zoxide" 2>/dev/null || true
        fi

        # install man pages if present
        if test -d ./man; then
            mkdir -p "$pkg_src_dir/share"
            mv ./man "$pkg_src_dir/share/man"
        fi
    }

    # pkg_get_current_version is recommended, but (soon) not required
    pkg_get_current_version() {
        # 'zoxide --version' has output in this format:
        #       zoxide v0.5.0-31-g8452961
        # This trims it down to just the version number:
        #       0.5.0
        zoxide --version 2> /dev/null | head -n 1 | cut -d '-' -f 1 | cut -b '9-'
    }

    # shellcheck disable=SC2016
    pkg_done_message() {
        echo 'zoxide was installed successfully. Next, you'\''ll need to set it up on your shell:'
        echo ''
        echo '- For bash, add this line to ~/.bashrc:'
        echo '    eval "$(zoxide init bash)"'
        echo ''
        echo '- For fish, add this line to ~/.config/fish/config.fish:'
        echo '    zoxide init fish | source'
        echo ''
        echo '- For zsh, add this line to ~/.zshrc:'
        echo '    eval "$(zoxide init zsh)"'
        echo ''
        echo '- For any other shell, see the instructions at https://github.com/ajeetdsouza/zoxide.'
    }
}

__init_zoxide
