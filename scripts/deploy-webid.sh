#!/bin/sh
set -e
set -u

# Build and deploy webid to a target host

g_host="${1:-next.webi.sh}"
g_bin="webid"
g_out="agents/tmp/${g_bin}"
g_remote_bin="~/bin/${g_bin}"

case "${g_host}" in
	beta.webi.sh) g_remote_conf="~/srv/beta.webinstall.dev/installers/" ;;
	next.webi.sh) g_remote_conf="~/srv/next.webinstall.dev/installers/" ;;
	*) g_remote_conf="~/srv/webid/installers/" ;;
esac

fn_build() {
	b_version="$(git describe --tags --always 2> /dev/null || echo '0.0.0-dev')"
	b_commit="$(git rev-parse --short HEAD)"
	b_date="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
	b_ldflags="-X main.version=${b_version} -X main.commit=${b_commit} -X main.date=${b_date}"

	printf 'Building %s %s %s (%s)...\n' "${g_bin}" "${b_version}" "${b_commit}" "${b_date}"
	GOOS=linux GOARCH=amd64 GOAMD64=v2 go build -ldflags "${b_ldflags}" -o "${g_out}" ./cmd/webid
	printf 'Built: %s\n' "${g_out}"
}

fn_deploy() {
	printf 'Stopping %s on %s...\n' "${g_bin}" "${g_host}"
	ssh "${g_host}" "~/.local/bin/serviceman stop ${g_bin}" 2> /dev/null || true

	printf 'Uploading binary...\n'
	scp "${g_out}" "${g_host}:${g_remote_bin}"

	printf 'Syncing install scripts and templates...\n'
	rsync -av \
		--exclude='_cache' --exclude='.git' --exclude='agents' \
		--exclude='bin' --exclude='cmd' --exclude='internal' \
		--exclude='docs' --exclude='scripts' --exclude='node_modules' \
		--include='*/' --include='install.sh' --include='install.ps1' \
		--include='_webi/*.tpl.sh' --include='_webi/*.tpl.ps1' \
		--exclude='*' \
		./ "${g_host}:${g_remote_conf}"
}

fn_start() {
	printf 'Starting %s...\n' "${g_bin}"
	ssh "${g_host}" "~/.local/bin/serviceman start ${g_bin}" || {
		printf 'Service not configured. Run serviceman add on the host:\n'
		printf '  serviceman add --name %s \\\n' "${g_bin}"
		printf '    --workdir %s -- \\\n' "${g_remote_conf}"
		printf '    %s \\\n' "${g_remote_bin}"
		printf '      --addr :3082 \\\n'
		printf '      --legacy ~/.cache/webi/legacy \\\n'
		printf '      --installers %s\n' "${g_remote_conf}"
		exit 1
	}
}

fn_verify() {
	printf 'Waiting 3s for startup...\n'
	sleep 3

	printf 'Checking version...\n'
	ssh "${g_host}" "${g_remote_bin} -V"

	printf 'Checking health...\n'
	ssh "${g_host}" "curl -s http://localhost:3082/api/releases/bat.json | head -c 100"
	printf '\n'

	printf 'Checking logs...\n'
	ssh "${g_host}" "sudo journalctl -u ${g_bin} --no-pager -n 5"
}

fn_build
fn_deploy
fn_start
fn_verify

printf '\nDone. %s deployed to %s.\n' "${g_bin}" "${g_host}"
