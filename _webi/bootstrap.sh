#!/bin/bash

{

#WEBI_PKG=
#WEBI_HOST=https://webinstall.dev
export WEBI_HOST

mkdir -p "$HOME/.local/bin"

cat << EOF > "$HOME/.local/bin/webi"
#!/bin/bash

set -e
set -u

{

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
# NOTE: the order here is least favorable to most favorable
if [ -n "\$(command -v pkgutil)" ]; then
	my_ext="pkg,\$my_ext"
fi
# disable this check for the sake of building the macOS installer on Linux
#if [ -n "\$(command -v diskutil)" ]; then
	# note: could also detect via hdiutil
	my_ext="dmg,\$my_ext"
#fi
if [ -n "\$(command -v git)" ]; then
	my_ext="git,\$my_ext"
fi
if [ -n "\$(command -v unxz)" ]; then
	my_ext="xz,\$my_ext"
fi
if [ -n "\$(command -v unzip)" ]; then
	my_ext="zip,\$my_ext"
fi
if [ -n "\$(command -v tar)" ]; then
	my_ext="tar,\$my_ext"
fi
my_ext="\$(echo "\$my_ext" | sed 's/,$//')" # nix trailing comma
set -e

##
## Detect http client
##
set +e
export WEBI_CURL="\$(command -v curl)"
export WEBI_WGET="\$(command -v wget)"
set -e

export WEBI_BOOT="\$(mktemp -d -t "\$my_package-bootstrap.XXXXXXXX")"
export WEBI_HOST="\${WEBI_HOST:-https://webinstall.dev}"
export WEBI_UA="\$(uname -a)"

my_installer_url="\$WEBI_HOST/api/installers/\$my_package.bash?formats=\$my_ext"
set +e
if [ -n "\$WEBI_CURL" ]; then
	curl -fsSL "\$my_installer_url" -H "User-Agent: curl \$WEBI_UA" \\
		-o "\$WEBI_BOOT/\$my_package-bootstrap.sh"
else
	wget -q "\$my_installer_url" --user-agent="wget \$WEBI_UA" \\
		-O "\$WEBI_BOOT/\$my_package-bootstrap.sh"
fi
if ! [ \$? -eq 0 ]; then
  echo "error fetching '\$my_installer_url'"
  exit 1
fi
set -e

pushd "\$WEBI_BOOT" 2>&1 > /dev/null
	bash "\$my_package-bootstrap.sh"
popd 2>&1 > /dev/null

rm -rf "\$WEBI_BOOT"

}
EOF

chmod a+x "$HOME/.local/bin/webi"

if [ -n "${WEBI_PKG:-}" ]; then
    "$HOME/.local/bin/webi" "${WEBI_PKG}"
fi

}
