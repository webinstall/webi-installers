#!/bin/bash

# title: Serviceman
# homepage: https://git.rootprojects.org/root/serviceman
# tagline: cross-platform service management for Linux, Mac, and Windows
# description: |
#   Works with
#   - Launchd (macOS)
#   - Systemd (Linux)
#   - Windows Registry

set -e
set -u

# Get arch envs, etc
my_url="https://rootprojects.org/serviceman/dist/$(uname -s)/$(uname -m)/serviceman"
curl -fL "$my_url" -o serviceman
echo ""
# Make executable
chmod +x ./serviceman
# Move to ~/.local/bin
mkdir -p ~/.local/bin
mv ./serviceman ~/.local/bin

# Test if in PATH
set +e
my_serviceman=$(command -v serviceman)
set -e
if [ -n "$my_serviceman" ]; then
	if [ "$my_serviceman" != "$HOME/.local/bin/serviceman" ]; then
		echo "a serviceman installation (which make take precedence) exists at:"
		echo "    $my_serviceman"
		echo ""
	fi
fi

# add to ~/.local/bin to PATH, just in case
pathman add ~/.local/bin # > /dev/null 2> /dev/null
# TODO inform user to add to path, apart from pathman?
