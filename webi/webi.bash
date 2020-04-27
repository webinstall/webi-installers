#!/bin/bash

# title: Webi
# homepage: https://webinstall.dev
# tagline: webinstall.dev for the CLI
# description: |
#   for the people like us that are too lazy even to run `curl https://webinstall.dev/PACKAGE_NAME` - just `webi PACKAGE_NAME` instead

# TODO webi package@semver#channel

cat << EOF > ~/.local/bin/webi
set -e
set -u

my_package=\${1:-}
if [ -z "\$my_package" ]; then
	echo "Usage: webi <package>"
	echo "Example: webi node"
	exit 1
fi

curl -fsSL "https://webinstall.dev/\$my_package" | bash
EOF
chmod a+x ~/.local/bin/webi
