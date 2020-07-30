#!/bin/bash

# The custom install functions and variables are here.
# The generic functions - version checks, download, extract, etc - are here:
#   - https://github.com/webinstall/packages/branches/master/_webi/template.sh

{
    set -e
    set -u

    # Every package should define these 6 variables
    pkg_cmd_name="node"

    # ~/.local/opt/node
    pkg_dst_cmd="$WEBI_PREFIX/opt/node/bin/node"
    pkg_dst="$WEBI_PREFIX/opt/node"

    # ~/.local/opt/node-v14.7.0/bin/node
    pkg_src_cmd="$WEBI_PREFIX/opt/node-v$WEBI_VERSION/bin/node"
    pkg_src_dir="$WEBI_PREFIX/opt/node-v$WEBI_VERSION"
    pkg_src="$pkg_src_dir"

    # pkg_install must be defined by each package
    pkg_install() {
        # mkdir -p ~/.local/opt
        mkdir -p "$(dirname $pkg_src)"

        # mv ./node* ~/.local/opt/node-v14.7.0
        mv ./node* "$pkg_src"
    }

    pkg_link() {
        # rm -f ~/.local/opt/node
        rm -f "$pkg_dst"

        # ln -s ~/.local/opt/node-v14.7.0 ~/.local/opt/node
        ln -s "$pkg_src" "$pkg_dst"

        # Node bugfix: use the correct version of node, even if PATH has a conflict
        "$pkg_src"/bin/node "$pkg_src"/bin/npm config set scripts-prepend-node-path=true
    }

    pkg_done_message() {
        echo "Installed 'node' and 'npm' at $pkg_dst"
    }

    pkg_get_current_version() {
        # 'node --version' has output in this format:
        #       v12.8.0
        # This trims it down to just the version number:
        #       12.8.0
        echo "$(node --version 2>/dev/null | head -n 1 | cut -d' ' -f1 | sed 's:^v::')"
    }
}
