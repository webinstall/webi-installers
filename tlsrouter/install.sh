#!/bin/sh
# shellcheck disable=SC2034,SC2154

set -e
set -u

__init_tlsrouter() {
	pkg_cmd_name="tlsrouter"

	pkg_dst_cmd="$HOME/.local/bin/tlsrouter"
	pkg_dst="$pkg_dst_cmd"

	pkg_src_cmd="$HOME/.local/opt/tlsrouter-v$WEBI_VERSION/bin/tlsrouter"
	pkg_src_dir="$HOME/.local/opt/tlsrouter-v$WEBI_VERSION"
	pkg_src="$pkg_src_cmd"

	pkg_install() {
		mkdir -p "$pkg_src_bin"
		mv ./tlsrouter "$pkg_src_cmd"
		chmod a+x "$pkg_src_cmd"
	}
}

__init_tlsrouter
