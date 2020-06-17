#!/bin/bash

# title: Pathman
# homepage: https://git.rootprojects.org/root/pathman
# tagline: |
#   Pathman: cross-platform PATH management for bash, zsh, fish, cmd.exe, and PowerShell.
# description: |
#   Manages PATH on various OSes and shells
#     - Mac, Windows, Linux
#     - Bash, Zsh, Fish
#     - Command, Powershell
# examples: |
#   ```bash
#   pathman add ~/.local/bin
#   ```
#   <br/>
#
#   ```bash
#   pathman remove ~/.local/bin
#   ```
#   <br/>
#
#   ```bash
#   pathman list
#   ```


set -e
set -u

pkg_cmd_name="pathman"
WEBI_SINGLE=true

pkg_get_current_version() {
    echo $(pathman version 2>/dev/null | head -n 1 | cut -d ' ' -f2 | sed 's:^v::')
}

x_pkg_pre_install() {
    # Test if in PATH
    set +e
    my_pathman=$(command -v pathman)
    set -e
    if [ -n "$my_pathman" ]; then
        # TODO test pathman version
        # if [ "$WEBI_VERSION" == "$(pathman version | cut -d ' ' -f2)" ]; then
        if [ "$my_pathman" != "$HOME/.local/bin/pathman" ]; then
            echo "a pathman installation (which make take precedence) exists at:"
            echo "    $my_pathman"
            echo ""
        fi
        echo "pathman already installed"
        exit 0
    fi
}

x_pkg_install() {
    # TODO use webi_download via releases.js
    mkdir -p "$HOME/.local/bin/"
    webi_check
    webi_download
    webi_download
    # webi_download "https://rootprojects.org/pathman/dist/$(uname -s)/$(uname -m)/pathman"
    mv "$HOME/Downloads/pathman-v0.5.2" "$HOME/.local/bin/pathman"
    chmod +x "$HOME/.local/bin/pathman"
}

x_pkg_link() {
    true
}

pkg_post_install() {
    # add to ~/.local/bin to PATH even if pathman is elsewhere
    # TODO pathman needs silent option and debug output (quiet "already exists" output)
    # TODO inform user to add to path, apart from pathman?
    "$HOME/.local/bin/pathman" add "$HOME/.local/bin"
}

pkg_done_message() {
    true
}
