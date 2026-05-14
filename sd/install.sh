#!/bin/sh
set -e
set -u

__init_sd() {

    ##################
    # Install sd #
    ##################

    # Every package should define these 6 variables
    pkg_cmd_name="sd"

    pkg_dst_cmd="$HOME/.local/bin/sd"
    pkg_dst="$pkg_dst_cmd"

    pkg_src_cmd="$HOME/.local/opt/sd-v$WEBI_VERSION/bin/sd"
    pkg_src_dir="$HOME/.local/opt/sd-v$WEBI_VERSION"
    pkg_src="$pkg_src_cmd"

    # pkg_install must be defined by every package
    pkg_install() {
        # mv ./sd-*/sd "$pkg_src_cmd"
        if test -f sd-*; then
            # ~/.local/opt/sd-v0.99.9/bin
            mkdir -p "$(dirname "$pkg_src_cmd")"
            mv sd-* "$pkg_src_cmd"
        elif test -f sd-*/sd; then
            # ~/.local/opt/sd-v0.99.9/bin
            mkdir -p "$(dirname "$pkg_src_cmd")"
            mv sd-*/sd "$pkg_src_cmd"

            # install completions if present (completions/{sd.bash,sd.fish,_sd})
            if test -d sd-*/completions; then
                mkdir -p "$pkg_src_dir/share/bash-completion/completions"
                mkdir -p "$pkg_src_dir/share/fish/vendor_completions.d"
                mkdir -p "$pkg_src_dir/share/zsh/site-functions"
                mv sd-*/completions/sd.bash "$pkg_src_dir/share/bash-completion/completions/sd" 2>/dev/null || true
                mv sd-*/completions/sd.fish "$pkg_src_dir/share/fish/vendor_completions.d/sd.fish" 2>/dev/null || true
                mv sd-*/completions/_sd "$pkg_src_dir/share/zsh/site-functions/_sd" 2>/dev/null || true
            fi

            # install man page if present
            if test -f sd-*/sd.1; then
                mkdir -p "$pkg_src_dir/share/man/man1"
                mv sd-*/sd.1 "$pkg_src_dir/share/man/man1/sd.1"
            fi
        elif test -d sd-*/bin; then
            mv sd-* "$pkg_src_dir"
        fi
    }

    # pkg_get_current_version is recommended, but (soon) not required
    pkg_get_current_version() {
        # 'sd --version' has output in this format:
        #       sd 0.99.9 (rev abcdef0123)
        # This trims it down to just the version number:
        #       0.99.9
        sd --version 2> /dev/null | head -n 1 | cut -d ' ' -f 2
    }

}

__init_sd
