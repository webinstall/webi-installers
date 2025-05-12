#!/bin/sh
set -e
set -u

# The package name should be the command name
# (this will be different for rust, go, node, etc)
pkg_cmd_name="zen"

# Every package gets its own directory
pkg_dst_cmd="$HOME/.local/bin/zen"
pkg_dst="$HOME/.local/opt/zen"

# Different packages represent the version in different ways
# You may need to change these lines
pkg_src_cmd="$HOME/.local/opt/zen-v$WEBI_VERSION/zen"
pkg_src="$HOME/.local/opt/zen-v$WEBI_VERSION"

# Different packages have different ways of checking the current version
pkg_get_current_version() {
    # 'zen --version' should output something like "Zen Browser 115.0.2"
    # and we want to extract just the version number
    if [ -x "$pkg_dst_cmd" ]; then
        # Extract version number from output like "Zen Browser 115.0.2" -> "115.0.2"
        "$pkg_dst_cmd" --version 2> /dev/null | head -n 1 | cut -d' ' -f3
    else
        echo "0.0.0"
    fi
}

# For packages that need special install handling, you can define
# pkg_pre_install, pkg_install, and pkg_post_install
pkg_pre_install() {
    # web_* are defined in _webi/template.sh
    # $WEBI_TMP is set by _webi/bootstrap.sh
    webi_check
    webi_download
    webi_extract
}

pkg_install() {
    # Setup directories
    mkdir -p "$pkg_src"

    # Different handling based on file extension
    if [ -n "$(ls "$WEBI_TMP/"*.tar.xz 2> /dev/null)" ]; then
        # Handle .tar.xz (Linux)
        echo "Installing from .tar.xz archive"

        # Move contents to installation directory
        mv "$WEBI_TMP"/* "$pkg_src/" 2> /dev/null || true
        chmod +x "$pkg_src/zen"

    elif [ -n "$(ls "$WEBI_TMP/"*.appimage 2> /dev/null)" ]; then
        # Handle .AppImage (Linux)
        echo "Installing from AppImage"

        # Move AppImage to installation directory
        find "$WEBI_TMP" -name "*.appimage" -o -name "*.AppImage" | while read -r appimage; do
            mv "$appimage" "$pkg_src/zen"
            chmod +x "$pkg_src/zen"
        done

    elif [ -n "$(ls "$WEBI_TMP/"*.dmg 2> /dev/null)" ]; then
        # Handle .dmg (macOS)
        echo "Installing from .dmg (macOS)"

        # For macOS, we need to extract the app from the DMG
        # This is a simplified approach - may need adjustment for specific DMG structure
        if command -v hdiutil > /dev/null; then
            # Create a mount point
            DMG_FILE=$(ls "$WEBI_TMP"/*.dmg | head -n 1)
            MOUNT_POINT="$WEBI_TMP/dmg_mount"
            mkdir -p "$MOUNT_POINT"

            # Mount the DMG
            hdiutil attach "$DMG_FILE" -mountpoint "$MOUNT_POINT" -nobrowse -quiet

            # Copy the app to the destination
            if [ -d "$MOUNT_POINT/Zen.app" ]; then
                cp -R "$MOUNT_POINT/Zen.app" "$pkg_src/"
                # Create executable wrapper script
                echo '#!/bin/sh' > "$pkg_src/zen"
                echo "open \"$pkg_src/Zen.app\" \"\$@\"" >> "$pkg_src/zen"
                chmod +x "$pkg_src/zen"
            else
                echo "Error: Could not find Zen.app in the mounted DMG"
                ls -la "$MOUNT_POINT"
            fi

            # Unmount the DMG
            hdiutil detach "$MOUNT_POINT" -quiet || true
        else
            echo "Error: 'hdiutil' command not found, cannot mount DMG"
        fi
    fi
}

pkg_post_install() {
    # Add to PATH if it's not already there
    webi_path_add "$HOME/.local/bin"
}

# Run the installer
webi_check

if [ -n "${WEBI_SINGLE:-}" ]; then
    pkg_get_current_version
    pkg_install
else
    _webi_hook_run_pkg
fi

# A note on versions:
# pkg_get_current_version must:
# - output only a version number to stdout (no additional text)
# - be fast (no version managers that run interpreters)
# - handle all cases, including when the program is not installed
