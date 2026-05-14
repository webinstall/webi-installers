#!/bin/sh
set -e
set -u

__init_rg() {

    ###################
    # Install ripgrep #
    ###################

    # Every package should define these 6 variables
    pkg_cmd_name="rg"

    pkg_dst_cmd="$HOME/.local/bin/rg"
    pkg_dst="$pkg_dst_cmd"

    pkg_src_cmd="$HOME/.local/opt/rg-v$WEBI_VERSION/bin/rg"
    pkg_src_dir="$HOME/.local/opt/rg-v$WEBI_VERSION"
    pkg_src="$pkg_src_cmd"

    # pkg_install must be defined by every package
    pkg_install() {
        # ~/.local/opt/rg-v12.1.1/bin
        mkdir -p "$(dirname "$pkg_src_cmd")"

        # mv ./ripgrep-*/rg ~/.local/opt/rg-v12.1.1/bin/rg
        mv ./ripgrep-*/rg "$pkg_src_cmd"

        # install completions if present (complete/_rg, complete/rg.bash, complete/rg.fish)
        if test -d ./ripgrep-*/complete; then
            mkdir -p "$pkg_src_dir/share/bash-completion/completions"
            mkdir -p "$pkg_src_dir/share/fish/vendor_completions.d"
            mkdir -p "$pkg_src_dir/share/zsh/site-functions"
            mv ./ripgrep-*/complete/rg.bash "$pkg_src_dir/share/bash-completion/completions/rg" 2>/dev/null || true
            mv ./ripgrep-*/complete/rg.fish "$pkg_src_dir/share/fish/vendor_completions.d/rg.fish" 2>/dev/null || true
            mv ./ripgrep-*/complete/_rg "$pkg_src_dir/share/zsh/site-functions/_rg" 2>/dev/null || true
        fi

        # install man page if present
        if test -f ./ripgrep-*/doc/rg.1; then
            mkdir -p "$pkg_src_dir/share/man/man1"
            mv ./ripgrep-*/doc/rg.1 "$pkg_src_dir/share/man/man1/rg.1"
        fi

        if ! [ -e ~/.ripgreprc ]; then
            touch ~/.ripgreprc
        fi
    }

    # pkg_get_current_version is recommended, but (soon) not required
    pkg_get_current_version() {
        # 'rg --version' has output in this format:
        #       ripgrep 12.1.1 (rev 7cb211378a)
        #       -SIMD -AVX (compiled)
        #       +SIMD -AVX (runtime)
        # This trims it down to just the version number:
        #       12.1.1
        rg --version 2> /dev/null | head -n 1 | cut -d ' ' -f 2
    }
}

__init_rg
