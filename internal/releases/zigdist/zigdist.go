// Package zigdist fetches Zig release data from ziglang.org.
//
// The API is a single JSON object keyed by version or branch name:
//
//	https://ziglang.org/download/index.json
//
// Each version key maps to an object containing "date", "notes", and
// platform keys like "x86_64-linux", "aarch64-macos", etc. Platform
// values have "tarball", "shasum", and "size" fields.
package zigdist

import (
	"context"
	"encoding/json"
	"fmt"
	"iter"
	"net/http"
)

// Release is one Zig version with its per-platform builds.
type Release struct {
	Version   string              `json:"version"` // set by us from the key or inner "version" field
	Date      string              `json:"date"`
	Notes     string              `json:"notes,omitempty"`
	Platforms map[string]Platform `json:"platforms,omitempty"` // "x86_64-linux" → Platform
}

// Platform is one downloadable artifact for a specific arch-os combo.
type Platform struct {
	Tarball string      `json:"tarball"`
	Shasum  string      `json:"shasum"`
	Size    json.Number `json:"size"` // upstream sends as string
}

// Fetch retrieves the Zig release index.
//
// Yields one batch containing all releases. The iterator interface exists
// so callers use the same pattern as paginated sources.
func Fetch(ctx context.Context, client *http.Client) iter.Seq2[[]Release, error] {
	return func(yield func([]Release, error) bool) {
		url := "https://ziglang.org/download/index.json"

		req, err := http.NewRequestWithContext(ctx, http.MethodGet, url, nil)
		if err != nil {
			yield(nil, fmt.Errorf("zigdist: %w", err))
			return
		}
		req.Header.Set("Accept", "application/json")

		resp, err := client.Do(req)
		if err != nil {
			yield(nil, fmt.Errorf("zigdist: fetch: %w", err))
			return
		}
		defer resp.Body.Close()

		if resp.StatusCode != http.StatusOK {
			yield(nil, fmt.Errorf("zigdist: fetch: %s", resp.Status))
			return
		}

		// The JSON is an object keyed by version/branch name.
		var raw map[string]json.RawMessage
		if err := json.NewDecoder(resp.Body).Decode(&raw); err != nil {
			yield(nil, fmt.Errorf("zigdist: decode: %w", err))
			return
		}

		var releases []Release
		for ref, data := range raw {
			rel, err := parseRelease(ref, data)
			if err != nil {
				yield(nil, fmt.Errorf("zigdist: parse %s: %w", ref, err))
				return
			}
			releases = append(releases, rel)
		}

		yield(releases, nil)
	}
}

// parseRelease extracts a Release from one version entry. The JSON mixes
// metadata fields ("date", "notes", "version", "src") with platform keys
// ("x86_64-linux", "aarch64-macos", etc.).
func parseRelease(ref string, data json.RawMessage) (Release, error) {
	// First pass: grab known metadata fields.
	var meta struct {
		Version string `json:"version"`
		Date    string `json:"date"`
		Notes   string `json:"notes"`
	}
	if err := json.Unmarshal(data, &meta); err != nil {
		return Release{}, err
	}

	version := meta.Version
	if version == "" {
		version = ref
	}

	// Second pass: grab all platform entries.
	var all map[string]json.RawMessage
	if err := json.Unmarshal(data, &all); err != nil {
		return Release{}, err
	}

	platforms := make(map[string]Platform)
	for key, val := range all {
		// Skip metadata keys.
		switch key {
		case "version", "date", "notes", "src":
			continue
		}
		var p Platform
		if err := json.Unmarshal(val, &p); err != nil {
			continue // not a platform object
		}
		if p.Tarball == "" {
			continue // not a platform object
		}
		platforms[key] = p
	}

	return Release{
		Version:   version,
		Date:      meta.Date,
		Notes:     meta.Notes,
		Platforms: platforms,
	}, nil
}
