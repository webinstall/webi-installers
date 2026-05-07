// Package iterm2dist fetches iTerm2 release URLs from the downloads page.
//
// iTerm2 doesn't have a structured API — releases are listed as links on:
//
//	https://iterm2.com/downloads.html
//
// This package scrapes download links matching iTerm2-[34]*.zip from the
// HTML and returns them as structured entries.
package iterm2dist

import (
	"context"
	"fmt"
	"io"
	"iter"
	"net/http"
	"regexp"
	"strings"
)

// Entry is one iTerm2 download link with extracted metadata.
type Entry struct {
	Version string `json:"version"` // "3.5.13"
	Channel string `json:"channel"` // "stable" or "beta"
	URL     string `json:"url"`     // full download URL
}

var linkRe = regexp.MustCompile(`href="(https://iterm2\.com/downloads/[^"]*\.zip)"`)
var versionRe = regexp.MustCompile(`iTerm2[-_]v?(\d+(?:_\d+)*)(?:[-_]?(beta|preview)[-_]?(\d*))?\.zip`)

// Fetch retrieves iTerm2 releases by scraping the downloads page.
//
// Yields one batch containing all releases.
func Fetch(ctx context.Context, client *http.Client) iter.Seq2[[]Entry, error] {
	return func(yield func([]Entry, error) bool) {
		url := "https://iterm2.com/downloads.html"

		req, err := http.NewRequestWithContext(ctx, http.MethodGet, url, nil)
		if err != nil {
			yield(nil, fmt.Errorf("iterm2dist: %w", err))
			return
		}
		req.Header.Set("Accept", "text/html")

		resp, err := client.Do(req)
		if err != nil {
			yield(nil, fmt.Errorf("iterm2dist: fetch: %w", err))
			return
		}
		defer resp.Body.Close()

		if resp.StatusCode != http.StatusOK {
			yield(nil, fmt.Errorf("iterm2dist: fetch: %s", resp.Status))
			return
		}

		body, err := io.ReadAll(resp.Body)
		if err != nil {
			yield(nil, fmt.Errorf("iterm2dist: read: %w", err))
			return
		}

		matches := linkRe.FindAllStringSubmatch(string(body), -1)
		var entries []Entry
		seen := make(map[string]bool)
		for _, m := range matches {
			link := m[1]
			// Only include iTerm2 v3+ downloads.
			if !strings.Contains(link, "iTerm2-3") && !strings.Contains(link, "iTerm2-4") {
				continue
			}

			entry := Entry{URL: link}

			// Determine channel from URL path.
			if strings.Contains(link, "/stable/") {
				entry.Channel = "stable"
			} else {
				entry.Channel = "beta"
			}

			// Extract version: iTerm2-3_5_13.zip → 3.5.13
			vm := versionRe.FindStringSubmatch(link)
			if vm != nil {
				entry.Version = strings.ReplaceAll(vm[1], "_", ".")
				// vm[2] = "beta" or "preview", vm[3] = optional number
				if vm[2] != "" {
					entry.Version += "-" + vm[2] + vm[3]
				}
			}

			// The downloads page has duplicate links for some betas
			// (e.g. iTerm2-3_5_1beta1.zip and iTerm2-3_5_1_beta1.zip).
			// Keep the first URL encountered per version.
			if seen[entry.Version] {
				continue
			}
			seen[entry.Version] = true

			entries = append(entries, entry)
		}

		yield(entries, nil)
	}
}
