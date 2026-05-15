// Package gitea fetches releases from a Gitea or Forgejo instance.
//
// Gitea's release API lives under:
//
//	GET {baseurl}/api/v1/repos/{owner}/{repo}/releases
//
// The response shape is similar to GitHub's but not identical. This package
// handles pagination, authentication, and deserialization independently.
package gitea

import (
	"context"
	"encoding/json"
	"fmt"
	"iter"
	"net/http"
	"regexp"
	"strings"
)

// Release is one release from the Gitea releases API.
type Release struct {
	TagName     string  `json:"tag_name"`
	Name        string  `json:"name"`
	Prerelease  bool    `json:"prerelease"`
	Draft       bool    `json:"draft"`
	PublishedAt string  `json:"published_at"` // "2023-11-05T06:38:05Z"
	Assets      []Asset `json:"assets"`
	TarballURL  string  `json:"tarball_url"`
	ZipballURL  string  `json:"zipball_url"`
}

// Asset is one downloadable file attached to a release.
type Asset struct {
	Name               string `json:"name"`                 // "pathman-v0.6.0-darwin-amd64.tar.gz"
	BrowserDownloadURL string `json:"browser_download_url"` // full URL
	Size               int64  `json:"size"`
}

// Auth holds optional credentials for authenticated API access.
type Auth struct {
	Token string // personal access token or API key
}

// Fetch retrieves releases from a Gitea instance, paginating automatically.
// Each yield is one page of releases.
//
// The baseURL should be the Gitea root (e.g. "https://git.rootprojects.org").
// The /api/v1 prefix is appended automatically.
func Fetch(ctx context.Context, client *http.Client, baseURL, owner, repo string, auth *Auth) iter.Seq2[[]Release, error] {
	return func(yield func([]Release, error) bool) {
		base := strings.TrimRight(baseURL, "/")
		page := 1

		for {
			url := fmt.Sprintf("%s/api/v1/repos/%s/%s/releases?limit=50&page=%d",
				base, owner, repo, page)

			req, err := http.NewRequestWithContext(ctx, http.MethodGet, url, nil)
			if err != nil {
				yield(nil, fmt.Errorf("gitea: %w", err))
				return
			}
			req.Header.Set("Accept", "application/json")
			if auth != nil && auth.Token != "" {
				req.Header.Set("Authorization", "token "+auth.Token)
			}

			resp, err := client.Do(req)
			if err != nil {
				yield(nil, fmt.Errorf("gitea: fetch %s: %w", url, err))
				return
			}

			if resp.StatusCode != http.StatusOK {
				resp.Body.Close()
				yield(nil, fmt.Errorf("gitea: fetch %s: %s", url, resp.Status))
				return
			}

			var releases []Release
			err = json.NewDecoder(resp.Body).Decode(&releases)
			resp.Body.Close()
			if err != nil {
				yield(nil, fmt.Errorf("gitea: decode %s: %w", url, err))
				return
			}

			if !yield(releases, nil) {
				return
			}

			// Gitea uses Link headers like GitHub for pagination.
			if nextURL := nextPageURL(resp.Header.Get("Link")); nextURL != "" {
				url = nextURL
				page++ // not strictly needed since we follow the URL, but keeps logic clear
				continue
			}

			// No next link — also stop if we got fewer results than requested.
			if len(releases) < 50 {
				return
			}
			page++
		}
	}
}

var reNextLink = regexp.MustCompile(`<([^>]+)>;\s*rel="next"`)

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
