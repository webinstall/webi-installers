#!/bin/sh
set -e
set -u

__init_nextdeployd() {
    # Package-specific variables
    pkg_cmd_name="nextdeployd"
    
    pkg_dst="$HOME/.local/opt/nextdeployd"
    pkg_dst_cmd="$HOME/.local/bin/nextdeployd"
    
    pkg_src="$HOME/.local/opt/nextdeployd-v$WEBI_VERSION"
    pkg_src_cmd="$HOME/.local/opt/nextdeployd-v$WEBI_VERSION/bin/nextdeployd"
    
    # Ex: ~/.local/opt/nextdeployd-v0.1.0/bin
    pkg_src_bin="$(dirname "$pkg_src_cmd")"
    # Ex: ~/.local/opt/nextdeployd/bin
    pkg_dst_bin="$(dirname "$pkg_dst_cmd")"
}

pkg_get_current_version() {
    # 'nextdeployd version' has output in this format:
    #       nextdeployd version 0.1.0
    # This trims it down to just the version number:
    #       0.1.0
    nextdeployd version 2> /dev/null |
        head -n 1 |
        cut -d' ' -f3 ||
        echo "0.0.0"
}

pkg_install() {
    # Move the extracted binary to the versioned directory
    mkdir -p "$(dirname "$pkg_src_cmd")"
    
    # The downloaded file will be named like: nextdeployd-linux-amd64
    # We need to rename it to just 'nextdeployd'
    mv "$WEBI_TMP"/nextdeployd* "$pkg_src_cmd"
    chmod a+x "$pkg_src_cmd"
}

pkg_post_install() {
    # Create symlink from versioned to current
    webi_link
    
    # Add to PATH
    webi_path_add "$pkg_dst_bin"
    
    # Install systemd service if systemd is available
    if command -v systemctl > /dev/null 2>&1; then
        install_systemd_service
    fi
}

install_systemd_service() {
    echo ""
    echo "Setting up systemd service..."
    
    # Create systemd service file
    sudo tee /etc/systemd/system/nextdeployd.service > /dev/null <<EOF
[Unit]
Description=NextDeploy Daemon
Documentation=https://github.com/aynaash/nextdeploy
After=network.target docker.service
Requires=docker.service

[Service]
Type=simple
User=root
ExecStart=$pkg_dst_cmd
Restart=on-failure
RestartSec=10
StandardOutput=journal
StandardError=journal

[Install]
WantedBy=multi-user.target
EOF
    
    # Reload systemd
    sudo systemctl daemon-reload
    
    echo "Systemd service installed. To enable and start:"
    echo "    sudo systemctl enable nextdeployd"
    echo "    sudo systemctl start nextdeployd"
}

pkg_done_message() {
    echo "Installed 'nextdeployd' v$WEBI_VERSION as $pkg_dst_cmd"
    echo ""
    echo "The NextDeploy daemon is now installed."
    echo ""
    if command -v systemctl > /dev/null 2>&1; then
        echo "To start the daemon:"
        echo "    sudo systemctl enable nextdeployd"
        echo "    sudo systemctl start nextdeployd"
        echo ""
        echo "To check status:"
        echo "    sudo systemctl status nextdeployd"
        echo ""
        echo "To view logs:"
        echo "    journalctl -u nextdeployd -f"
    else
        echo "To start the daemon manually:"
        echo "    sudo $pkg_dst_cmd"
    fi
    echo ""
    echo "For CLI installation:"
    echo "    curl https://webi.sh/nextdeploy | sh"
}

__init_nextdeployd
