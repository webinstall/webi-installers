#!/bin/bash

# title: Webi
# homepage: https://webinstall.dev
# tagline: webinstall.dev for the CLI
# description: |
#   for the people like us that are too lazy even to run <kbd>curl&nbsp;https://webinstall.dev/PACKAGE_NAME&nbsp;|&nbsp;bash</kbd>
# examples: |
#   ```bash
#   webi node@latest
#   ```
#   <br/>
#
#   ```bash
#   webi golang@v1.14
#   ```
#   <br/>
#
#   ```bash
#   webi rustlang
#   ```

{

mkdir -p "$HOME/.local/bin"

cat << EOF > "$HOME/.local/bin/webi"
#!/bin/bash

set -e
set -u

my_package="\${1:-}"
if [ -z "\$my_package" ]; then
	echo "Usage: webi <package>@<version>"
	echo "Example: webi node@latest"
	exit 1
fi

##
## Detect acceptable package formats
##

my_ext=""
set +e
if [ -n "\$(command -v git)" ]; then
	my_ext="git,\${my_ext}"
fi
if [ -n "\$(command -v tar)" ]; then
	my_ext="tar,\${my_ext}"
fi
if [ -n "\$(command -v unzip)" ]; then
	my_ext="zip,\${my_ext}"
fi
if [ -n "\$(command -v pkgutil)" ]; then
	my_ext="pkg,\${my_ext}"
fi
if [ -n "\$(command -v diskutil)" ]; then
	# note: could also detect via hdiutil
	my_ext="dmg,\${my_ext}"
fi
set -e

##
## Detect http client
##
set +e
export WEBI_CURL="\$(command -v curl)"
export WEBI_WGET="\$(command -v wget)"
set -e

export WEBI_BOOT="\$(mktemp -d -t "\$my_package-bootstrap.XXXXXXXX")"
export WEBI_UA="\$(uname -a)"

if [ -n "\$WEBI_CURL" ]; then
	curl -fsSL "https://webinstall.dev/\$my_package?ext=\$my_ext" -H "User-Agent: curl \$WEBI_UA" \\
		-o "\$WEBI_BOOT/\$my_package-bootstrap.sh"
else
	wget -q "https://webinstall.dev/\$my_package?ext=\$my_ext" --user-agent="wget \$WEBI_UA" \\
		-O "\$WEBI_BOOT/\$my_package-bootstrap.sh"
fi

pushd "\$WEBI_BOOT" 2>&1 > /dev/null
	bash "\$my_package-bootstrap.sh"
popd 2>&1 > /dev/null

rm -rf "\$WEBI_BOOT"
EOF

chmod a+x ~/.local/bin/webi

}
