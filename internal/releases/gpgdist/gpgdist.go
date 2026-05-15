// Package gpgdist fetches GPG for macOS release data from SourceForge RSS.
//
// The gpgosx project publishes DMG installers on SourceForge. The RSS feed
// at https://sourceforge.net/projects/gpgosx/rss?path=/ lists download links
// for each version.
package gpgdist

import (
	"context"
	"fmt"
	"io"
	"iter"
	"net/http"
	"regexp"
)

// Entry is one GPG macOS release.
type Entry struct {
	Version string `json:"version"` // "2.4.7"
	URL     string `json:"url"`     // full SourceForge download URL
}

var linkRe = regexp.MustCompile(
	`<link>(https://sourceforge\.net/projects/gpgosx/files/GnuPG-([\d.]+)\.dmg/download)</link>`,
)

// Fetch retrieves GPG macOS releases from the SourceForge RSS feed.
//
// Yields one batch containing all releases.
func Fetch(ctx context.Context, client *http.Client) iter.Seq2[[]Entry, error] {
	return func(yield func([]Entry, error) bool) {
		url := "https://sourceforge.net/projects/gpgosx/rss?path=/"

		req, err := http.NewRequestWithContext(ctx, http.MethodGet, url, nil)
		if err != nil {
			yield(nil, fmt.Errorf("gpgdist: %w", err))
			return
		}
		req.Header.Set("Accept", "application/rss+xml")

		resp, err := client.Do(req)
		if err != nil {
			yield(nil, fmt.Errorf("gpgdist: fetch: %w", err))
			return
		}
		defer resp.Body.Close()

		if resp.StatusCode != http.StatusOK {
			yield(nil, fmt.Errorf("gpgdist: fetch: %s", resp.Status))
			return
		}

		body, err := io.ReadAll(resp.Body)
		if err != nil {
			yield(nil, fmt.Errorf("gpgdist: read: %w", err))
			return
		}

		matches := linkRe.FindAllStringSubmatch(string(body), -1)
		var entries []Entry
		for _, m := range matches {
			entries = append(entries, Entry{
				URL:     m[1],
				Version: m[2],
			})
		}

		yield(entries, nil)
	}
}
