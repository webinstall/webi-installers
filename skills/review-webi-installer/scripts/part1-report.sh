#!/bin/sh
# Generate the data-driven Part 1 report for a Webi installer PR.

set -eu

if test "$#" -ne 2; then
	printf 'usage: %s PR_URL OUTPUT.md\n' "$0" >&2
	exit 2
fi

pr_url=$1
output=$2

case "$pr_url" in
	https://github.com/*/pull/[0-9]*) ;;
	*) printf 'error: expected https://github.com/OWNER/REPO/pull/NUMBER\n' >&2; exit 2 ;;
esac

repo_path=$(printf '%s\n' "$pr_url" | sed -n 's#^https://github.com/\([^/][^/]*/[^/][^/]*\)/pull/[0-9][0-9]*$#\1#p')
pr_number=$(printf '%s\n' "$pr_url" | sed -n 's#^.*/pull/\([0-9][0-9]*\)$#\1#p')
api="https://api.github.com/repos/${repo_path}"
tmp_dir=$(mktemp -d "${TMPDIR:-/tmp}/webi-review.XXXXXXXX")
trap 'rm -rf "$tmp_dir"' EXIT HUP INT TERM

relative_time() {
	iso=$1
	case "$iso" in
		'' | unknown | none) printf '%s' "$iso"; return ;;
	esac
	if epoch=$(date -u -j -f '%Y-%m-%dT%H:%M:%SZ' "$iso" '+%s' 2>/dev/null); then
		:
	elif epoch=$(date -u -d "$iso" '+%s' 2>/dev/null); then
		:
	else
		printf '%s' unknown
		return
	fi
	now=$(date -u '+%s')
delta=$((now - epoch))
test "$delta" -ge 0 || delta=0
if test "$delta" -lt 3600; then
	value=$((delta / 60))
	test "$value" -gt 1 || { printf '%s' 'just now'; return; }
	printf '%s minutes ago' "$value"
elif test "$delta" -lt 86400; then
	printf '%s hours ago' "$((delta / 3600))"
elif test "$delta" -lt 2592000; then
	printf '%s days ago' "$((delta / 86400))"
elif test "$delta" -lt 31536000; then
	printf '%s months ago' "$((delta / 2592000))"
else
	printf '%s years ago' "$((delta / 31536000))"
fi
}

curl_api() {
	url=$1
	if test -n "${GITHUB_TOKEN:-}"; then
		curl -fsSL \
			-H 'Accept: application/vnd.github+json' \
			-H "Authorization: Bearer ${GITHUB_TOKEN}" \
			"$url"
	else
		curl -fsSL -H 'Accept: application/vnd.github+json' "$url"
	fi
}

curl_api "$api/pulls/$pr_number" > "$tmp_dir/pr.json"
curl_api "$api/pulls/$pr_number/files?per_page=100" > "$tmp_dir/files.json"
curl_api "$api/commits/$(jq -r '.head.sha' "$tmp_dir/pr.json")/check-runs?per_page=100" > "$tmp_dir/checks.json"
author=$(jq -r '.user.login' "$tmp_dir/pr.json")
curl_api "https://api.github.com/users/$author" > "$tmp_dir/author.json"
curl_api "https://api.github.com/users/$author/repos?type=owner&sort=updated&direction=desc&per_page=100" > "$tmp_dir/author-repos.json"

upstream_repo_path=$(jq -r '
	(.body // "") as $body |
	(.base.repo.full_name // "") as $base |
	(.head.repo.full_name // "") as $head |
	[$body | scan("https://github\\.com/[A-Za-z0-9_.-]+/[A-Za-z0-9_.-]+")
		| sub("^https://github\\.com/"; "")
		| select(. != $base and . != $head)] | .[0] // ""
' "$tmp_dir/pr.json")
if test -n "$upstream_repo_path"; then
	curl_api "https://api.github.com/repos/$upstream_repo_path" > "$tmp_dir/upstream-repo.json"
	curl_api "https://api.github.com/repos/$upstream_repo_path/releases?per_page=100" > "$tmp_dir/upstream-releases.json"
	curl_api "https://api.github.com/repos/$upstream_repo_path/issues?state=all&sort=updated&direction=desc&per_page=1" > "$tmp_dir/upstream-latest-issue.json"
else
	printf '%s\n' '{}' > "$tmp_dir/upstream-repo.json"
	printf '%s\n' '[]' > "$tmp_dir/upstream-releases.json"
	printf '%s\n' '[]' > "$tmp_dir/upstream-latest-issue.json"
fi

upstream_owner=$(jq -r '.owner.login // ""' "$tmp_dir/upstream-repo.json")
if test -n "$upstream_owner" && test "$(printf '%s' "$upstream_owner" | tr '[:upper:]' '[:lower:]')" != "$(printf '%s' "$author" | tr '[:upper:]' '[:lower:]')"; then
	upstream_owner_type=$(jq -r '.owner.type // "User"' "$tmp_dir/upstream-repo.json")
	if test "$upstream_owner_type" = 'Organization'; then
		curl_api "https://api.github.com/orgs/$upstream_owner" > "$tmp_dir/upstream-owner.json"
		curl_api "https://api.github.com/orgs/$upstream_owner/repos?type=owner&sort=updated&direction=desc&per_page=100" > "$tmp_dir/upstream-owner-repos.json"
	else
		curl_api "https://api.github.com/users/$upstream_owner" > "$tmp_dir/upstream-owner.json"
		curl_api "https://api.github.com/users/$upstream_owner/repos?type=owner&sort=updated&direction=desc&per_page=100" > "$tmp_dir/upstream-owner-repos.json"
	fi
else
	printf '%s\n' '{}' > "$tmp_dir/upstream-owner.json"
	printf '%s\n' '[]' > "$tmp_dir/upstream-owner-repos.json"
fi

repo=$repo_path
author_created=$(jq -r '.created_at // "unknown"' "$tmp_dir/author.json")
author_followers=$(jq -r '.followers // 0' "$tmp_dir/author.json")
author_public_repos=$(jq -r '.public_repos // 0' "$tmp_dir/author.json")
author_top_starred=$(jq -r 'sort_by([(.stargazers_count // 0), .full_name]) | reverse | .[:3] | .[] | "- [\(.full_name)](\(.html_url)) — \(.stargazers_count // 0) stars; last push \(.pushed_at // "unknown")"' "$tmp_dir/author-repos.json")
author_top_active=$(jq -r 'sort_by([(.pushed_at // ""), .full_name]) | reverse | .[:3] | .[] | "- [\(.full_name)](\(.html_url)) — last push \(.pushed_at // "unknown"); \(.stargazers_count // 0) stars"' "$tmp_dir/author-repos.json")
upstream_owner_created=$(jq -r '.created_at // "unknown"' "$tmp_dir/upstream-owner.json")
upstream_owner_followers=$(jq -r '.followers // 0' "$tmp_dir/upstream-owner.json")
upstream_owner_public_repos=$(jq -r '.public_repos // 0' "$tmp_dir/upstream-owner.json")
upstream_owner_top_starred=$(jq -r 'sort_by([(.stargazers_count // 0), .full_name]) | reverse | .[:3] | .[] | "- [\(.full_name)](\(.html_url)) — \(.stargazers_count // 0) stars; last push \(.pushed_at // "unknown")"' "$tmp_dir/upstream-owner-repos.json")
upstream_owner_top_active=$(jq -r 'sort_by([(.pushed_at // ""), .full_name]) | reverse | .[:3] | .[] | "- [\(.full_name)](\(.html_url)) — last push \(.pushed_at // "unknown"); \(.stargazers_count // 0) stars"' "$tmp_dir/upstream-owner-repos.json")
upstream_repo=$(jq -r '.full_name // "not identified from PR description"' "$tmp_dir/upstream-repo.json")
if test -n "$upstream_repo_path"; then
	upstream_url="https://github.com/$upstream_repo"
else
	upstream_url='not identified from PR description'
fi
upstream_owner_type=$(jq -r '.owner.type // "unknown"' "$tmp_dir/upstream-repo.json")
upstream_created=$(jq -r '.created_at // "unknown"' "$tmp_dir/upstream-repo.json")
upstream_pushed=$(jq -r '.pushed_at // "unknown"' "$tmp_dir/upstream-repo.json")
upstream_stars=$(jq -r '.stargazers_count // 0' "$tmp_dir/upstream-repo.json")
upstream_forks=$(jq -r '.forks_count // 0' "$tmp_dir/upstream-repo.json")
upstream_issues=$(jq -r '.open_issues_count // 0' "$tmp_dir/upstream-repo.json")
upstream_releases=$(jq 'length' "$tmp_dir/upstream-releases.json")
upstream_latest_release=$(jq -r '.[0].published_at // "none"' "$tmp_dir/upstream-releases.json")
upstream_latest_issue=$(jq -r '.[0] | if .number then "#\(.number) \(.updated_at) \(.html_url)" else "none" end' "$tmp_dir/upstream-latest-issue.json")
pr_created=$(jq -r '.created_at // "unknown"' "$tmp_dir/pr.json")
pr_updated=$(jq -r '.updated_at // "unknown"' "$tmp_dir/pr.json")
pr_title=$(jq -r '.title' "$tmp_dir/pr.json")
pr_source=$(jq -r 'if .head.repo.full_name then "\(.head.repo.full_name):\(.head.ref) @ \(.head.sha)" else "unknown" end' "$tmp_dir/pr.json")
pr_changed=$(jq 'length' "$tmp_dir/files.json")
check_count=$(jq '.check_runs | length' "$tmp_dir/checks.json")
check_summary=$(jq -r '[.check_runs[] | "\(.name): \(.conclusion // .status)"] | join(", ")' "$tmp_dir/checks.json")

mkdir -p "$(dirname "$output")"
{
	printf '%s\n' "# Part 1 report: ${repo} PR #${pr_number}"
	printf '\n%s\n' "Generated: $(date -u '+%Y-%m-%dT%H:%M:%SZ')"
	printf '\n## PR\n\n'
	printf '%s\n' "- URL: ${pr_url}" "- Title: ${pr_title}" "- Source: ${pr_source}" "- Opened: ${pr_created} ($(relative_time "$pr_created"))" "- Updated: ${pr_updated} ($(relative_time "$pr_updated"))" "- Changed files: ${pr_changed}" "- Checks: ${check_count} (${check_summary:-none})"
	printf '\n## Upstream repository\n\n'
	printf '%s\n' "- URL: ${upstream_url}" "- Owner type: ${upstream_owner_type}" "- Created: ${upstream_created} ($(relative_time "$upstream_created"))" "- Last push: ${upstream_pushed} ($(relative_time "$upstream_pushed"))" "- Stars: ${upstream_stars}" "- Forks: ${upstream_forks}" "- Open issues: ${upstream_issues}" "- Releases returned: ${upstream_releases}" "- Latest release: ${upstream_latest_release} ($(relative_time "$upstream_latest_release"))" "- Latest issue/update: ${upstream_latest_issue}"
	if test -n "$upstream_owner" && test "$(printf '%s' "$upstream_owner" | tr '[:upper:]' '[:lower:]')" != "$(printf '%s' "$author" | tr '[:upper:]' '[:lower:]')"; then
		printf '\n## Package Author\n\n'
		printf '%s\n' "- Account or organization: https://github.com/${upstream_owner}" "- Type: ${upstream_owner_type}" "- Created: ${upstream_owner_created} ($(relative_time "$upstream_owner_created"))" "- Followers: ${upstream_owner_followers}" "- Public repositories: ${upstream_owner_public_repos}"
		printf '\n### Top 3 by stars\n\n%s\n' "${upstream_owner_top_starred:-none}"
		printf '\n### Top 3 by recent activity\n\n%s\n' "${upstream_owner_top_active:-none}"
	fi
	printf '\n## PR Author\n\n'
	printf '%s\n' "- Account: https://github.com/${author}" "- Created: ${author_created} ($(relative_time "$author_created"))" "- Followers: ${author_followers}" "- Public repositories: ${author_public_repos}"
	printf '\n### Top 3 by stars\n\n%s\n' "${author_top_starred:-none}"
	printf '\n### Top 3 by recent activity\n\n%s\n' "${author_top_active:-none}"
	printf '\n## Changed files\n\n'
	jq -r '.[] | "- `\(.status)` `\(.filename)` (+\(.additions)/-\(.deletions))"' "$tmp_dir/files.json"
	printf '\n## Temperature check\n\n'
	printf '%s\n' '- [ ] Human/AI reviewed scope, identity consistency, and changed files.' '- [ ] Continue to Part 2.'
} > "$output"

printf 'wrote %s\n' "$output"
