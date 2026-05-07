// Package chromedist fetches Chrome for Testing release data.
//
// Google publishes a JSON index of known-good Chrome/ChromeDriver versions at:
//
//	https://googlechromelabs.github.io/chrome-for-testing/known-good-versions-with-downloads.json
//
// Each version entry has per-platform download URLs for chrome, chromedriver,
// and chrome-headless-shell.
package chromedist

import (
	"context"
	"encoding/json"
	"fmt"
	"iter"
	"net/http"
)

// Index is the top-level response.
type Index struct {
	Timestamp string    `json:"timestamp"`
	Versions  []Version `json:"versions"`
}

// Version is one Chrome for Testing version with its downloads.
type Version struct {
	Version   string               `json:"version"`  // "121.0.6120.0"
	Revision  string               `json:"revision"` // "1222902"
	Downloads map[string][]Download `json:"downloads"` // "chromedriver" → []Download
}

// Download is one platform-specific download URL.
type Download struct {
	Platform string `json:"platform"` // "linux64", "mac-arm64", "mac-x64", "win32", "win64"
	URL      string `json:"url"`
}

// Fetch retrieves the Chrome for Testing release index.
//
// Yields one batch containing all versions.
func Fetch(ctx context.Context, client *http.Client) iter.Seq2[[]Version, error] {
	return func(yield func([]Version, error) bool) {
		url := "https://googlechromelabs.github.io/chrome-for-testing/known-good-versions-with-downloads.json"

		req, err := http.NewRequestWithContext(ctx, http.MethodGet, url, nil)
		if err != nil {
			yield(nil, fmt.Errorf("chromedist: %w", err))
			return
		}
		req.Header.Set("Accept", "application/json")

		resp, err := client.Do(req)
		if err != nil {
			yield(nil, fmt.Errorf("chromedist: fetch: %w", err))
			return
		}
		defer resp.Body.Close()

		if resp.StatusCode != http.StatusOK {
			yield(nil, fmt.Errorf("chromedist: fetch: %s", resp.Status))
			return
		}

		var idx Index
		if err := json.NewDecoder(resp.Body).Decode(&idx); err != nil {
			yield(nil, fmt.Errorf("chromedist: decode: %w", err))
			return
		}

		yield(idx.Versions, nil)
	}
}
