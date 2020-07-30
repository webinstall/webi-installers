#!/bin/bash

# The custom install functions and variables are here.
# The generic functions - version checks, download, extract, etc - are here:
#   - https://github.com/webinstall/packages/branches/master/_webi/template.sh

{
    set -e
    set -u

    ###################
    # Install ripgrep #
    ###################

    # Every package should define these 6 variables
    pkg_cmd_name="rg"

    # ~/.local/bin/rg
    pkg_dst_cmd="$WEBI_PREFIX/bin/rg"
    pkg_dst="$pkg_dst_cmd"

    # ~/.local/opt/ripgrep-v12.1.1/bin/rg
    pkg_src_cmd="$WEBI_PREFIX/opt/ripgrep-v$WEBI_VERSION/rg"
    pkg_src_dir="$WEBI_PREFIX/opt/ripgrep-v$WEBI_VERSION"
    pkg_src="$pkg_src_cmd"

    # pkg_install must be defined by every package
    pkg_install() {
        # mv ./ripgrep-*/rg ~/.local/opt/rg-v12.1.1
        mv ./ripgrep-* "$pkg_src_dir"
    }

    pkg_link() {
        # 'pkg_dst' should be $HOME/.local/opt/<pkg> or $HOME/.local/bin/<cmd>
        rm -rf "$pkg_dst"

        # 'pkg_src' will be the installed version, such as to $HOME/.local/opt/<pkg>-v<version>
        ln -s "$pkg_src" "$pkg_dst"

        # update bash completions
        # See https://serverfault.com/a/1013395/93930
        rm -rf ~/.local/share/bash-completion/completions/rg.bash
        mkdir -p ~/.local/share/bash-completion/completions/
        ln -s "$pkg_src_dir/complete/rg.bash" ~/.local/share/bash-completion/completions/

        # update fish completions
        # See https://stackoverflow.com/a/20839388/151312
        rm -rf ~/.config/fish/completions/rg.fish
        mkdir -p ~/.config/fish/completions/
        ln -s "$pkg_src_dir/complete/rg.fish" ~/.config/fish/completions/
    }

    # pkg_get_current_version is recommended, but (soon) not required
    pkg_get_current_version() {
        # 'rg --version' has output in this format:
        #       ripgrep 12.1.1 (rev 7cb211378a)
        #       -SIMD -AVX (compiled)
        #       +SIMD -AVX (runtime)
        # This trims it down to just the version number:
        #       12.1.1
      echo $(rg --version 2>/dev/null | head -n 1 | cut -d ' ' -f 2)
    }
}
