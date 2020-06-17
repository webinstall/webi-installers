#!/bin/bash

# title: Serviceman
# homepage: https://git.rootprojects.org/root/serviceman
# tagline: |
#   Serviceman: cross-platform service management for Linux, Mac, and Windows.
# description: |
#   Serviceman is a hassle-free wrapper around your system launcher. It works with `launchctl` (macOS), `systemctl` (Linux), and the Windows Registry to make it easy to start _user_ and _system_ level services, such as webservers, backup scripts, network and system tools, etc.
# examples: |
#
#   Works with anything, including
#
#   ### Node.js
#
#   ```bash
#   serviceman add --name my-service node ./serve.js --port 3000
#   ```
#
#   ### Golang
#
#   ```bash
#   go build -mod vendor cmd/my-service
#   serviceman add ./my-service --port 3000
#   ```
#
#   ### And even bash!
#
#   ```bash
#   serviceman add --name backuper bash ./backup.sh /mnt/data
#   ```

set -e
set -u

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

# Get arch envs, etc
webi_download "https://rootprojects.org/serviceman/dist/$(uname -s)/$(uname -m)/serviceman" "$HOME/Downloads/serviceman"
chmod +x "$HOME/Downloads/serviceman"
mv "$HOME/Downloads/serviceman" "$HOME/.local/bin/"

# add to ~/.local/bin to PATH, just in case
webi_path_add $HOME/.local/bin # > /dev/null 2> /dev/null
# TODO inform user to add to path, apart from pathman?
