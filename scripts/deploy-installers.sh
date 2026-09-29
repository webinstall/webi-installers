#!/bin/sh
# shellcheck disable=SC2087,SC2088
# Deploy package installer files and refresh release caches.

set -Cue

fn_deploy_package() {
	b_pkg=$1

	if ! test -d "$b_pkg"; then
		printf 'error: package directory not found: %s\n' "$b_pkg" >&2
		exit 1
	fi
	if ! test -f "$b_pkg/install.sh" && ! test -f "$b_pkg/install.ps1"; then
		printf 'error: installer not found in package: %s\n' "$b_pkg" >&2
		exit 1
	fi

	printf 'Syncing %s to %s...\n' "$b_pkg" "$g_host"
	rsync -av "${b_pkg}/" "${g_host}:${g_remote_conf}/${b_pkg}/"

	printf 'Refreshing %s release cache...\n' "$b_pkg"
	ssh "$g_host" << SSH_EOF
set -Cue
. ~/.config/envman/PATH.env
webicached \
  --conf ${g_remote_conf}/ \
  --raw ~/.cache/webi/raw \
  --once "${b_pkg}"
SSH_EOF

	printf 'Checking %s installer endpoint...\n' "$b_pkg"
	curl -fsSL "${g_public_host}/${b_pkg}" > /dev/null
	printf 'Done: %s on %s\n' "$b_pkg" "$g_host"
}

fn_main() {
	if test "$#" -lt 2; then
		printf 'usage: %s HOST PACKAGE...\n' "$0" >&2
		printf 'hosts: beta.webi.sh next.webi.sh webi.sh\n' >&2
		exit 2
	fi

	g_host=$1
	shift

	g_remote_conf=''
	g_public_host=''
	case "$g_host" in
		beta.webi.sh)
			g_remote_conf='~/srv/beta.webinstall.dev/installers'
			g_public_host='https://beta.webi.sh'
			;;
		next.webi.sh)
			g_remote_conf='~/srv/next.webinstall.dev/installers'
			g_public_host='https://next.webi.sh'
			;;
		webi.sh)
			g_remote_conf='~/srv/webinstall.dev/installers'
			g_public_host='https://webinstall.dev'
			;;
		*)
			printf 'error: unsupported host: %s\n' "$g_host" >&2
			exit 2
			;;
	esac

	for b_pkg in "$@"; do
		fn_deploy_package "$b_pkg"
	done
}

fn_main "$@"
