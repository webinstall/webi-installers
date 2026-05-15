// Package flutterdist fetches Flutter release data from Google Storage.
//
// Flutter publishes per-OS release indexes:
//
//	https://storage.googleapis.com/flutter_infra_release/releases/releases_macos.json
//	https://storage.googleapis.com/flutter_infra_release/releases/releases_linux.json
//	https://storage.googleapis.com/flutter_infra_release/releases/releases_windows.json
//
// Each response has a base_url and a releases array with version, channel,
// release_date, archive path, and sha256.
package flutterdist

import (
	"context"
	"encoding/json"
	"fmt"
	"iter"
	"net/http"
)

// index is the top-level JSON structure for one OS endpoint.
type index struct {
	BaseURL  string    `json:"base_url"`
	Releases []Release `json:"releases"`
}

// Release is one Flutter release entry.
type Release struct {
	Hash        string `json:"hash"`         // git commit hash
	Channel     string `json:"channel"`      // "stable", "beta", "dev"
	Version     string `json:"version"`      // "3.29.2"
	ReleaseDate string `json:"release_date"` // "2025-03-13T00:14:34.044690Z"
	Archive     string `json:"archive"`      // "stable/macos/flutter_macos_arm64_3.29.2-stable.zip"
	SHA256      string `json:"sha256"`

	// DownloadURL is the fully-qualified URL, assembled from base_url + archive.
	// Not in the upstream JSON — set by Fetch.
	DownloadURL string `json:"download_url"`
	// OS is the platform this entry came from ("macos", "linux", "windows").
	// Not in the upstream JSON — set by Fetch.
	OS string `json:"os"`
}

var defaultOSes = []string{"macos", "linux", "windows"}

// Fetch retrieves Flutter releases for all platforms.
//
// Yields one batch per OS. The iterator interface exists so callers use
// the same pattern as paginated sources.
func Fetch(ctx context.Context, client *http.Client) iter.Seq2[[]Release, error] {
	return func(yield func([]Release, error) bool) {
		for _, osName := range defaultOSes {
			url := fmt.Sprintf(
				"https://storage.googleapis.com/flutter_infra_release/releases/releases_%s.json",
				osName,
			)

			req, err := http.NewRequestWithContext(ctx, http.MethodGet, url, nil)
			if err != nil {
				yield(nil, fmt.Errorf("flutterdist: %w", err))
				return
			}
			req.Header.Set("Accept", "application/json")

			resp, err := client.Do(req)
			if err != nil {
				yield(nil, fmt.Errorf("flutterdist: fetch %s: %w", osName, err))
				return
			}

			var idx index
			err = json.NewDecoder(resp.Body).Decode(&idx)
			resp.Body.Close()
			if err != nil {
				yield(nil, fmt.Errorf("flutterdist: decode %s: %w", osName, err))
				return
			}

			if resp.StatusCode != http.StatusOK {
				yield(nil, fmt.Errorf("flutterdist: fetch %s: %s", osName, resp.Status))
				return
			}

			for i := range idx.Releases {
				idx.Releases[i].DownloadURL = idx.BaseURL + "/" + idx.Releases[i].Archive
				idx.Releases[i].OS = osName
			}

			if !yield(idx.Releases, nil) {
				return
			}
		}
	}
}
