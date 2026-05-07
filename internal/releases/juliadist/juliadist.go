// Package juliadist fetches Julia release data from the Julia S3 API.
//
// Julia publishes a version index at:
//
//	https://julialang-s3.julialang.org/bin/versions.json
//
// The response is a JSON object keyed by version string, where each value
// has a "files" array of downloadable artifacts with url, triplet, kind,
// arch, os, sha256, size, and extension fields.
package juliadist

import (
	"context"
	"encoding/json"
	"fmt"
	"iter"
	"net/http"
)

// Release is one Julia version with its file artifacts.
type Release struct {
	Version string `json:"version"` // set by us from the key
	Stable  bool   `json:"stable"`
	Files   []File `json:"files"`
}

// File is one downloadable artifact.
type File struct {
	URL       string `json:"url"`       // full download URL
	Triplet   string `json:"triplet"`   // "aarch64-apple-darwin14"
	Kind      string `json:"kind"`      // "archive" or "installer"
	Arch      string `json:"arch"`      // "aarch64", "x86_64", "i686"
	OS        string `json:"os"`        // "mac", "linux", "winnt"
	SHA256    string `json:"sha256"`
	Size      int64  `json:"size"`
	Version   string `json:"version"`   // same as release version
	Extension string `json:"extension"` // "tar.gz", "dmg", "exe"
}

// rawRelease is the upstream JSON shape (stable as bool, files array).
type rawRelease struct {
	Stable bool   `json:"stable"`
	Files  []File `json:"files"`
}

// Fetch retrieves the Julia release index.
//
// Yields one batch containing all releases.
func Fetch(ctx context.Context, client *http.Client) iter.Seq2[[]Release, error] {
	return func(yield func([]Release, error) bool) {
		url := "https://julialang-s3.julialang.org/bin/versions.json"

		req, err := http.NewRequestWithContext(ctx, http.MethodGet, url, nil)
		if err != nil {
			yield(nil, fmt.Errorf("juliadist: %w", err))
			return
		}
		req.Header.Set("Accept", "application/json")

		resp, err := client.Do(req)
		if err != nil {
			yield(nil, fmt.Errorf("juliadist: fetch: %w", err))
			return
		}
		defer resp.Body.Close()

		if resp.StatusCode != http.StatusOK {
			yield(nil, fmt.Errorf("juliadist: fetch: %s", resp.Status))
			return
		}

		var raw map[string]rawRelease
		if err := json.NewDecoder(resp.Body).Decode(&raw); err != nil {
			yield(nil, fmt.Errorf("juliadist: decode: %w", err))
			return
		}

		var releases []Release
		for version, r := range raw {
			releases = append(releases, Release{
				Version: version,
				Stable:  r.Stable,
				Files:   r.Files,
			})
		}

		yield(releases, nil)
	}
}
