#!/bin/bash

# The custom install functions and variables are here.
# The generic functions - version checks, download, extract, etc - are here:
#   - https://github.com/webinstall/packages/branches/master/_webi/template.sh

{
    set -e
    set -u

    #################
    # Install hexyl #
    #################

    # All 6 of these variables must be defined for every package
    pkg_cmd_name="hexyl"

    pkg_dst_cmd="$WEBI_PREFIX/bin/hexyl"
    pkg_dst="$pkg_dst_cmd"

    pkg_src_cmd="$WEBI_PREFIX/opt/hexyl-v$WEBI_VERSION/bin/hexyl"
    pkg_src_dir="$WEBI_PREFIX/opt/hexyl-v$WEBI_VERSION"
    pkg_src="$pkg_src_cmd"

    # pkg_install must be defined for every package
    pkg_install() {
        # mkdir -p ~/.local/opt/hexyl-v0.8.0/bin
        mkdir -p "$(dirname "$pkg_src_cmd")"

        # mv ./hexyl-*/hexyl ~/.local/opt/hexyl-v0.8.0/bin/hexyl
        mv ./hexyl-*/hexyl "$pkg_src_cmd"

        # chmod a+x ~/.local/opt/hexyl-v0.8.0/bin/hexyl
        chmod a+x "$pkg_src_cmd"
    }

    # pkg_get_current_version is recommended, but (soon) not required
    pkg_get_current_version() {
      # 'hexyl --version' has output in this format:
      #       hexyl 0.8.0
      # This trims it down to just the version number:
      #       0.8.0
      echo $(hexyl --version 2>/dev/null | head -n 1 | cut -d' ' -f 2)
    }
}
