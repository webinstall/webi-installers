// Package gitlab fetches releases from a GitLab instance.
//
// GitLab's releases API differs from GitHub's in structure:
//
//	GET /api/v4/projects/:id/releases
//
// Where :id is the URL-encoded project path (e.g. "group%2Frepo") or a
// numeric project ID. Assets are split into auto-generated source archives
// and manually attached links. Pagination uses page/per_page query params
// and X-Total-Pages response headers (not Link headers).
//
// This package handles pagination, authentication, and deserialization.
// It does not transform or normalize the data.
package gitlab

import (
	"context"
	"encoding/json"
	"fmt"
	"iter"
	"net/http"
	"net/url"
	"strconv"
)

// Release is one release from the GitLab releases API.
type Release struct {
	TagName    string `json:"tag_name"`
	Name       string `json:"name"`
	ReleasedAt string `json:"released_at"` // "2025-10-22T13:00:26Z"
	Assets     Assets `json:"assets"`
}

// Assets holds both auto-generated source archives and attached links.
type Assets struct {
	Sources []Source `json:"sources"`
	Links   []Link   `json:"links"`
}

// Source is an auto-generated source archive (tar.gz, zip, etc.).
type Source struct {
	Format string `json:"format"` // "zip", "tar.gz", "tar.bz2", "tar"
	URL    string `json:"url"`
}

// Link is a file attached to a release (binary, package, etc.).
type Link struct {
	ID              int    `json:"id"`
	Name            string `json:"name"`
	URL             string `json:"url"`
	DirectAssetPath string `json:"direct_asset_path"`
	LinkType        string `json:"link_type"` // "other", "runbook", "image", "package"
}

// Auth holds optional credentials for authenticated API access.
type Auth struct {
	Token string // personal access token or deploy token
}

// Fetch retrieves releases from a GitLab instance, paginating automatically.
// Each yield is one page of releases.
//
// The baseURL should be the GitLab root (e.g. "https://gitlab.com").
// The project is identified by its path (e.g. "group/repo") — it will be
// URL-encoded automatically.
func Fetch(ctx context.Context, client *http.Client, baseURL, project string, auth *Auth) iter.Seq2[[]Release, error] {
	return func(yield func([]Release, error) bool) {
		encodedProject := url.PathEscape(project)
		page := 1

		for {
			reqURL := fmt.Sprintf("%s/api/v4/projects/%s/releases?per_page=100&page=%d",
				baseURL, encodedProject, page)

			req, err := http.NewRequestWithContext(ctx, http.MethodGet, reqURL, nil)
			if err != nil {
				yield(nil, fmt.Errorf("gitlab: %w", err))
				return
			}
			req.Header.Set("Accept", "application/json")
			if auth != nil && auth.Token != "" {
				req.Header.Set("PRIVATE-TOKEN", auth.Token)
			}

			resp, err := client.Do(req)
			if err != nil {
				yield(nil, fmt.Errorf("gitlab: fetch %s: %w", reqURL, err))
				return
			}

			if resp.StatusCode != http.StatusOK {
				resp.Body.Close()
				yield(nil, fmt.Errorf("gitlab: fetch %s: %s", reqURL, resp.Status))
				return
			}

			var releases []Release
			err = json.NewDecoder(resp.Body).Decode(&releases)
			resp.Body.Close()
			if err != nil {
				yield(nil, fmt.Errorf("gitlab: decode %s: %w", reqURL, err))
				return
			}

			if !yield(releases, nil) {
				return
			}

			// Check if there are more pages.
			totalPages := 1
			if tp := resp.Header.Get("X-Total-Pages"); tp != "" {
				if n, err := strconv.Atoi(tp); err == nil {
					totalPages = n
				}
			}
			if page >= totalPages {
				return
			}
			page++
		}
	}
}
