#!/bin/sh
# shellcheck disable=SC2034

set -e
set -u

__init_timeout() {
	pkg_cmd_name="timeout"

	pkg_dst_cmd="${HOME}/.local/bin/timeout"
	pkg_dst="${pkg_dst_cmd}"

	pkg_src_cmd="${HOME}/.local/opt/timeout-v${WEBI_VERSION}/bin/timeout"
	pkg_src_dir="${HOME}/.local/opt/timeout-v${WEBI_VERSION}"
	pkg_src="${pkg_src_cmd}"

	pkg_install() {
		pkg_src_bin=$(dirname "${pkg_src_cmd}")
		mkdir -p "${pkg_src_bin}"
		mv ./timeout "${pkg_src_cmd}"
	}

	# pkg_get_current_version is recommended, but (soon) not required
	pkg_get_current_version() {
		# 'timeout --version' has output in this format:
		#       timeout v0.0.0-dev 0000000 (0001-01-01)
		# This trims it down to just the version number:
		#       v0.0.0-dev
		timeout --version 2> /dev/null | head -n 1 | cut -d ' ' -f 2
	}
}

__init_timeout
