#!/bin/bash

# Package-specific variables
pkg_cmd_name="zen"
pkg_dst="$HOME/.local/opt/zen"
pkg_dst_cmd="$HOME/.local/opt/zen/zen"
pkg_src="$HOME/.local/opt/zen-v$WEBI_VERSION"
pkg_src_cmd="$HOME/.local/opt/zen-v$WEBI_VERSION/zen"

# Version check function
pkg_get_current_version() {
    # zen 1.0.0 => 1.0.0
    echo "$(zen --version 2> /dev/null | head -n 1 | sed 's/^.*[^0-9]\([0-9][0-9]*\.[0-9][0-9]*\.[0-9][0-9]*\).*$/\1/')"
}

# Pre-install tasks
pkg_pre_install() {
    # Standard webi pre-install tasks
    webi_check
    webi_download

    # AppImage doesn't need extraction
    if [[ $WEBI_PKG_FILE != *".AppImage" ]]; then
        webi_extract
    fi
}

# Install function - specific to Zen Browser
pkg_install() {
    # Move extracted files to the versioned directory
    mkdir -p "$(dirname $pkg_src)"
    rm -rf "$pkg_src"
    mkdir -p "$pkg_src"

    # Handle different file formats
    if [[ $WEBI_PKG_FILE == *".AppImage" ]]; then
        # AppImage: copy the single file and make executable
        if [[ $WEBI_PKG_FILE == *"-x86_64.AppImage" ]] || [[ $WEBI_PKG_FILE == *"-aarch64.AppImage" ]]; then
            # Handle AppImage files with different naming patterns
            cp "$WEBI_TMP/$WEBI_PKG_FILE" "$pkg_src_cmd"
        else
            # Regular AppImage naming
            cp "$WEBI_TMP/$WEBI_PKG_FILE" "$pkg_src_cmd"
        fi
        chmod +x "$pkg_src_cmd"
    elif [[ $WEBI_PKG_FILE == *".tar.xz" ]]; then
        # Tar archive: move extracted directory contents
        local extracted_dir=$(ls -1 "$WEBI_TMP" | grep -v "^$WEBI_PKG_FILE$" | head -n 1)
        if [ -n "$extracted_dir" ]; then
            mv "$WEBI_TMP/$extracted_dir"/* "$pkg_src/" 2> /dev/null || mv "$WEBI_TMP/$extracted_dir"/* "$pkg_src"
        else
            # If no subdirectory, move all files
            mv "$WEBI_TMP"/* "$pkg_src/" 2> /dev/null || true
        fi

        # Ensure the zen binary is executable
        chmod +x "$pkg_src_cmd" 2> /dev/null || true

        # If zen binary doesn't exist, look for other executables
        if [ ! -f "$pkg_src_cmd" ]; then
            local zen_exe=$(find "$pkg_src" -type f -name "zen*" -executable | head -n 1)
            if [ -n "$zen_exe" ]; then
                ln -sf "$zen_exe" "$pkg_src_cmd"
            fi
        fi
    fi

    # Final check to ensure the executable exists
    if [ ! -f "$pkg_src_cmd" ]; then
        echo "Error: Could not find zen executable. Installation may be incomplete."
        echo "Files in $pkg_src:"
        ls -la "$pkg_src"
        return 1
    fi
}

# Post-install tasks
pkg_post_install() {
    # Update PATH
    webi_path_add "$(dirname $pkg_dst_cmd)"

    # Create symlink to the installed version
    mkdir -p "$(dirname $pkg_dst_cmd)"
    ln -sf "$pkg_src_cmd" "$pkg_dst_cmd"

    # Create a convenience symlink in ~/.local/bin if it doesn't exist
    mkdir -p "$HOME/.local/bin"
    if [[ ! -e "$HOME/.local/bin/zen" ]]; then
        ln -sf "$pkg_dst_cmd" "$HOME/.local/bin/zen"
    fi
}

# Success message
pkg_done_message() {
    echo "Zen Browser v$WEBI_VERSION installed successfully!"
    echo ""
    echo "To run Zen Browser:"
    echo "  zen"
    echo ""
    echo "Configuration directory: ~/.config/zen/"
    echo ""
    echo "For more information:"
    echo "  - Documentation: https://docs.zen-browser.app/"
    echo "  - GitHub: https://github.com/zen-browser/desktop"
}
