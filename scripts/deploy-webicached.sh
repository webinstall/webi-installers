#!/bin/sh
# shellcheck disable=SC2029,SC2088
set -e
set -u

# Build and deploy webicached to a target host

g_host="${1:-beta.webi.sh}"
g_bin="webicached"
g_out="agents/tmp/${g_bin}"
g_remote_bin="~/bin/${g_bin}"

case "${g_host}" in
    beta.webi.sh) g_remote_conf="~/srv/beta.webinstall.dev/installers/" ;;
    next.webi.sh) g_remote_conf="~/srv/next.webinstall.dev/installers/" ;;
    webi.sh) g_remote_conf="~/srv/webinstall.dev/installers/" ;;
    *) g_remote_conf="~/srv/webinstall.dev/installers/" ;;
esac

fn_build() {
    b_tag="$(git describe --tags --abbrev=0 --match 'cmd/webicached/*' 2> /dev/null || echo 'cmd/webicached/v0.0.0')"
    b_tag_ver="$(printf '%s' "${b_tag}" | sed 's:^cmd/webicached/::')"
    b_count="$(git log --oneline "${b_tag}..HEAD" -- cmd/ internal/ 2> /dev/null | wc -l | tr -d ' \t')"
    b_commit="$(git rev-parse --short HEAD)"
    if test "${b_count}" -gt 0; then
        b_version="${b_tag_ver}-${b_count}-g${b_commit}"
    else
        b_version="${b_tag_ver}"
    fi
    b_date="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
    b_ldflags="-X main.version=${b_version} -X main.commit=${b_commit} -X main.date=${b_date}"

    printf 'Building %s %s %s (%s)...\n' "${g_bin}" "${b_version}" "${b_commit}" "${b_date}"
    GOOS=linux GOARCH=amd64 GOAMD64=v2 go build -ldflags "${b_ldflags}" -o "${g_out}" ./cmd/webicached
    printf 'Built: %s\n' "${g_out}"
}

fn_deploy() {
    printf 'Stopping %s on %s...\n' "${g_bin}" "${g_host}"
    ssh "${g_host}" "~/.local/bin/serviceman stop ${g_bin}" 2> /dev/null || true

    printf 'Uploading binary...\n'
    scp "${g_out}" "${g_host}:${g_remote_bin}"

    printf 'Syncing releases.conf files...\n'
    rsync -av \
        --exclude='_cache' --exclude='.git' --exclude='agents' \
        --exclude='bin' --exclude='cmd' --exclude='internal' \
        --exclude='docs' --exclude='scripts' --exclude='node_modules' \
        --include='*/' --include='releases.conf' --exclude='*' \
        ./ "${g_host}:${g_remote_conf}"

    printf 'Starting %s...\n' "${g_bin}"
    ssh "${g_host}" "~/.local/bin/serviceman start ${g_bin}"
}

fn_verify() {
    printf 'Waiting 5s for startup...\n'
    sleep 5

    printf 'Checking version...\n'
    ssh "${g_host}" "${g_remote_bin} -V"

    printf 'Checking logs...\n'
    ssh "${g_host}" "sudo journalctl -u ${g_bin} --no-pager -n 5"
}

fn_build
fn_deploy
fn_verify

printf '\nDone. %s deployed to %s.\n' "${g_bin}" "${g_host}"
