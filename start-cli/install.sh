#!/bin/bash
set -e
set -u

# Package-specific variables
pkg_cmd_name="start-cli"
pkg_dst_cmd="$HOME/.local/bin/start-cli"
pkg_dst="$HOME/.local/opt/start-cli"
pkg_dst_bin="$HOME/.local/opt/start-cli/bin"

# These will be set by webi
pkg_src_cmd="$HOME/.local/opt/start-cli-v$WEBI_VERSION/bin/start-cli"
pkg_src_bin="$HOME/.local/opt/start-cli-v$WEBI_VERSION/bin"
pkg_src="$HOME/.local/opt/start-cli-v$WEBI_VERSION"

pkg_get_current_version() {
    # 'start-cli version' outputs: start-cli v0.4.0-alpha.9
    echo "$(start-cli --version 2>/dev/null | head -n 1 | cut -d ' ' -f 2 | sed 's/v//')" || echo ""
}

pkg_install() {
    # Create the versioned directory
    mkdir -p "$(dirname $pkg_src_cmd)"

    # Move the binary from temp directory to the final location
    if [ -f "$WEBI_TMP/start-cli" ]; then
        mv "$WEBI_TMP/start-cli" "$pkg_src_cmd"
    elif [ -f "$WEBI_TMP/start-cli-"*"/start-cli" ]; then
        mv "$WEBI_TMP/start-cli-"*"/start-cli" "$pkg_src_cmd"
    else
        echo "Error: Could not find start-cli binary in temp directory"
        exit 1
    fi

    # Make it executable
    chmod +x "$pkg_src_cmd"
}

pkg_link() {
    # Remove any existing symlinks or files
    rm -f "$pkg_dst_cmd"

    # Create the symlink
    ln -s "$pkg_src_cmd" "$pkg_dst_cmd"
}

pkg_post_install() {
    # Add to PATH
    webi_path_add "$pkg_dst_bin"

    # Ensure the local bin directory is in PATH for immediate use
    webi_path_add "$HOME/.local/bin"
}

pkg_done_message() {
    echo "Installed 'start-cli' v$WEBI_VERSION to $pkg_src_cmd"
    echo ""
    echo "Try it out:"
    echo "    start-cli --help"
    echo "    start-cli --version"
}
