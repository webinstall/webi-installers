#!/bin/sh

__init_crush() {
	set -e
	set -u

	##################
	# Install crush #
	##################

	# Every package should define these 6 variables
	pkg_cmd_name="crush"

	pkg_dst_cmd="$HOME/.local/bin/crush"
	pkg_dst="$pkg_dst_cmd"

	pkg_src_cmd="$HOME/.local/opt/crush-v$WEBI_VERSION/bin/crush"
	pkg_src_dir="$HOME/.local/opt/crush-v$WEBI_VERSION"
	pkg_src="$pkg_src_cmd"

	pkg_install() {
		# $HOME/.local/opt/crush-v0.50.1/bin
		mkdir -p "$(dirname "$pkg_src_cmd")"

		# mv ./crush_*/* "$HOME/.local/opt/crush-v0.50.1/bin/"
		# (goreleaser puts binaries in a subdirectory with underscores: crush_VERSION_OS_arch/)
		mv ./crush_*/"$pkg_cmd_name" "$pkg_src_cmd"

		# chmod a+x "$HOME/.local/opt/crush-v0.50.1/bin/crush"
		chmod a+x "$pkg_src_cmd"
	}

	pkg_get_current_version() {
		# 'crush --version' has output in this format:
		#       0.50.1
		# This trims it down to just the version number:
		#       0.50.1
		crush --version 2>/dev/null | head -n 1 | sed 's:^v::'
	}

}

__init_crush
