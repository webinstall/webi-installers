#!/bin/bash

# title: Pathman
# homepage: https://git.rootprojects.org/root/pathman
# tagline: cross-platform PATH management for bash, zsh, fish, cmd.exe, and PowerShell
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

# Get arch envs, etc
my_url="https://rootprojects.org/pathman/dist/$(uname -s)/$(uname -m)/pathman"
curl -fsSL "$my_url" -o pathman
echo ""
# Make executable
chmod +x ./pathman
# Move to ~/.local/bin
mkdir -p ~/.local/bin
mv ./pathman ~/.local/bin

# Test if in PATH
set +e
my_pathman=$(command -v pathman)
set -e
if [ -n "$my_pathman" ]; then
	if [ "$my_pathman" != "$HOME/.local/bin/pathman" ]; then
		echo "a pathman installation (which make take precedence) exists at:"
		echo "    $my_pathman"
		echo ""
	fi
fi

# add to ~/.local/bin to PATH even if pathman is elsewhere
# TODO pathman needs silent option and debug output (quiet "already exists" output)
~/.local/bin/pathman add ~/.local/bin # > /dev/null 2> /dev/null
# TODO inform user to add to path, apart from pathman?
