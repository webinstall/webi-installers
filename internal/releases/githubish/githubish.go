// Package githubish fetches releases from GitHub-compatible APIs.
//
// GitHub, Gitea, Forgejo, and other forges expose the same releases
// endpoint shape:
//
//	GET /repos/{owner}/{repo}/releases
//
// This package handles pagination (Link headers), authentication, and
// deserialization. It does not transform or normalize the data.
package githubish

import (
	"context"
	"encoding/json"
	"fmt"
	"iter"
	"net/http"
	"regexp"
)

// Release is one release from a GitHub-compatible API.
// Fields mirror the upstream JSON — only the fields Webi cares about are
// included; the rest are silently dropped by the decoder.
type Release struct {
	TagName     string  `json:"tag_name"`
	Name        string  `json:"name"`
	Prerelease  bool    `json:"prerelease"`
	Draft       bool    `json:"draft"`
	PublishedAt string  `json:"published_at"` // "2025-10-22T13:00:26Z"
	Assets      []Asset `json:"assets"`
	TarballURL  string  `json:"tarball_url"`  // auto-generated source tarball
	ZipballURL  string  `json:"zipball_url"`  // auto-generated source zipball
}

// Asset is one downloadable file attached to a release.
type Asset struct {
	Name               string `json:"name"`                 // "ripgrep-15.1.0-x86_64-apple-darwin.tar.gz"
	BrowserDownloadURL string `json:"browser_download_url"` // full URL
	Size               int64  `json:"size"`
	ContentType        string `json:"content_type"`
}

// Auth holds optional credentials for authenticated API access.
// Without auth, GitHub's public rate limit is 60 requests/hour.
type Auth struct {
	Token string // personal access token or fine-grained token
}

// Fetch retrieves releases from a GitHub-compatible API, paginating
// automatically. Each yield is one page of releases.
//
// The baseURL should be the API root (e.g. "https://api.github.com").
// For Gitea: "https://gitea.example.com/api/v1".
func Fetch(ctx context.Context, client *http.Client, baseURL, owner, repo string, auth *Auth) iter.Seq2[[]Release, error] {
	return func(yield func([]Release, error) bool) {
		url := fmt.Sprintf("%s/repos/%s/%s/releases?per_page=100", baseURL, owner, repo)

		for url != "" {
			req, err := http.NewRequestWithContext(ctx, http.MethodGet, url, nil)
			if err != nil {
				yield(nil, fmt.Errorf("githubish: %w", err))
				return
			}
			req.Header.Set("Accept", "application/json")
			if auth != nil && auth.Token != "" {
				req.Header.Set("Authorization", "Bearer "+auth.Token)
			}

			resp, err := client.Do(req)
			if err != nil {
				yield(nil, fmt.Errorf("githubish: fetch %s: %w", url, err))
				return
			}

			if resp.StatusCode != http.StatusOK {
				resp.Body.Close()
				yield(nil, fmt.Errorf("githubish: fetch %s: %s", url, resp.Status))
				return
			}

			var releases []Release
			err = json.NewDecoder(resp.Body).Decode(&releases)
			resp.Body.Close()
			if err != nil {
				yield(nil, fmt.Errorf("githubish: decode %s: %w", url, err))
				return
			}

			if !yield(releases, nil) {
				return
			}

			url = nextPageURL(resp.Header.Get("Link"))
		}
	}
}

// reNextLink matches `<URL>; rel="next"` in a Link header.
var reNextLink = regexp.MustCompile(`<([^>]+)>;\s*rel="next"`)

// nextPageURL extracts the "next" URL from a GitHub Link header.
// Returns "" if there is no next page.
func nextPageURL(link string) string {
	if link == "" {
		return ""
	}
	m := reNextLink.FindStringSubmatch(link)
	if m == nil {
		return ""
	}
	return m[1]
}
