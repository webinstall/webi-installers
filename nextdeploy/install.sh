#!/bin/sh
set -e
set -u

__init_nextdeploy() {
    # Package-specific variables
    pkg_cmd_name="nextdeploy"
    
    pkg_dst="$HOME/.local/opt/nextdeploy"
    pkg_dst_cmd="$HOME/.local/bin/nextdeploy"
    
    pkg_src="$HOME/.local/opt/nextdeploy-v$WEBI_VERSION"
    pkg_src_cmd="$HOME/.local/opt/nextdeploy-v$WEBI_VERSION/bin/nextdeploy"
    
    # Ex: ~/.local/opt/nextdeploy-v0.1.0/bin
    pkg_src_bin="$(dirname "$pkg_src_cmd")"
    # Ex: ~/.local/opt/nextdeploy/bin
    pkg_dst_bin="$(dirname "$pkg_dst_cmd")"
}

pkg_get_current_version() {
    # 'nextdeploy version' has output in this format:
    #       nextdeploy version 0.1.0
    # This trims it down to just the version number:
    #       0.1.0
    nextdeploy version 2> /dev/null |
        head -n 1 |
        cut -d' ' -f3 ||
        echo "0.0.0"
}

pkg_install() {
    # Move the extracted binary to the versioned directory
    mkdir -p "$(dirname "$pkg_src_cmd")"
    
    # The downloaded file will be named like: nextdeploy-linux-amd64
    # We need to rename it to just 'nextdeploy'
    mv "$WEBI_TMP"/nextdeploy* "$pkg_src_cmd"
    chmod a+x "$pkg_src_cmd"
}

pkg_post_install() {
    # Create symlink from versioned to current
    webi_link
    
    # Add to PATH
    webi_path_add "$pkg_dst_bin"
}

pkg_done_message() {
    echo "Installed 'nextdeploy' v$WEBI_VERSION as $pkg_dst_cmd"
    echo ""
    echo "Get started:"
    echo "    nextdeploy init       # Initialize your Next.js project"
    echo "    nextdeploy build      # Build Docker image"
    echo "    nextdeploy ship       # Deploy to VPS"
    echo ""
    echo "For daemon installation (Linux only):"
    echo "    curl https://webi.sh/nextdeployd | sh"
}

__init_nextdeploy
