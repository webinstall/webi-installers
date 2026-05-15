// Package golang fetches Go release data from golang.org.
//
// The API returns all releases (including unstable) as a JSON array:
//
//	https://golang.org/dl/?mode=json&include=all
//
// Each release has a version string like "go1.24.1" and a list of file
// objects with filename, os, arch, sha256, size, and kind.
package golang

import (
	"context"
	"encoding/json"
	"fmt"
	"iter"
	"net/http"
)

// Release is one Go version from the download API.
type Release struct {
	Version string `json:"version"` // "go1.24.1"
	Stable  bool   `json:"stable"`
	Files   []File `json:"files"`
}

// File is one downloadable artifact within a release.
type File struct {
	Filename string `json:"filename"` // "go1.24.1.linux-amd64.tar.gz"
	OS       string `json:"os"`       // "linux", "darwin", "windows", ""
	Arch     string `json:"arch"`     // "amd64", "arm64", "386", ""
	Version  string `json:"version"`  // "go1.24.1"
	SHA256   string `json:"sha256"`
	Size     int64  `json:"size"`
	Kind     string `json:"kind"` // "archive", "installer", "source"
}

// Fetch retrieves the Go release index.
//
// Yields one batch containing all releases. The iterator interface exists
// so callers use the same pattern as paginated sources.
func Fetch(ctx context.Context, client *http.Client) iter.Seq2[[]Release, error] {
	return func(yield func([]Release, error) bool) {
		url := "https://golang.org/dl/?mode=json&include=all"

		req, err := http.NewRequestWithContext(ctx, http.MethodGet, url, nil)
		if err != nil {
			yield(nil, fmt.Errorf("golang: %w", err))
			return
		}
		req.Header.Set("Accept", "application/json")

		resp, err := client.Do(req)
		if err != nil {
			yield(nil, fmt.Errorf("golang: fetch: %w", err))
			return
		}
		defer resp.Body.Close()

		if resp.StatusCode != http.StatusOK {
			yield(nil, fmt.Errorf("golang: fetch: %s", resp.Status))
			return
		}

		var releases []Release
		if err := json.NewDecoder(resp.Body).Decode(&releases); err != nil {
			yield(nil, fmt.Errorf("golang: decode: %w", err))
			return
		}

		yield(releases, nil)
	}
}
