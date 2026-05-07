// Package nodedist fetches a Node.js-style distribution index.
//
// Node.js publishes a JSON index of all releases at:
//
//	https://nodejs.org/download/release/index.json
//
// Unofficial builds (musl, etc.) use the same format at:
//
//	https://unofficial-builds.nodejs.org/download/release/index.json
//
// This package fetches and deserializes that index. It does not classify,
// normalize, or transform the data — the caller gets what the API returns.
package nodedist

import (
	"context"
	"encoding/json"
	"fmt"
	"iter"
	"net/http"
)

// Entry is one release from a Node.js distribution index.
// Fields mirror the upstream JSON schema.
type Entry struct {
	Version  string   `json:"version"`  // "v25.8.0"
	Date     string   `json:"date"`     // "2026-03-03"
	Files    []string `json:"files"`    // ["linux-arm64", "osx-arm64-tar", ...]
	NPM      string   `json:"npm"`      // "11.11.0"
	V8       string   `json:"v8"`       // "14.1.146.11"
	UV       string   `json:"uv"`       // "1.51.0"
	Zlib     string   `json:"zlib"`     // "1.3.1"
	OpenSSL  string   `json:"openssl"`  // "3.5.5"
	Modules  string   `json:"modules"`  // "141"
	LTS      LTS      `json:"lts"`      // false or "Jod"
	Security bool     `json:"security"` // true if security release
}

// LTS holds the long-term support status. The upstream API encodes this as
// either the boolean false or a codename string like "Jod" or "Iron".
// An empty string means the release is not LTS.
type LTS string

func (l *LTS) UnmarshalJSON(data []byte) error {
	// false → ""
	if string(data) == "false" {
		*l = ""
		return nil
	}

	// "Codename" → Codename
	var s string
	if err := json.Unmarshal(data, &s); err != nil {
		return fmt.Errorf("nodedist: unexpected lts value: %s", data)
	}
	*l = LTS(s)
	return nil
}

func (l LTS) MarshalJSON() ([]byte, error) {
	if l == "" {
		return []byte("false"), nil
	}
	return json.Marshal(string(l))
}

// Fetch retrieves the Node.js distribution index from baseURL.
//
// The iterator yields one batch per HTTP response. The Node.js index API
// returns all releases in a single response, so there will be exactly one
// yield. The iterator interface exists so that callers use the same pattern
// for paginated sources (like GitHub).
//
// Standard base URLs:
//   - https://nodejs.org/download/release
//   - https://unofficial-builds.nodejs.org/download/release
func Fetch(ctx context.Context, client *http.Client, baseURL string) iter.Seq2[[]Entry, error] {
	return func(yield func([]Entry, error) bool) {
		url := baseURL + "/index.json"

		req, err := http.NewRequestWithContext(ctx, http.MethodGet, url, nil)
		if err != nil {
			yield(nil, fmt.Errorf("nodedist: %w", err))
			return
		}
		req.Header.Set("Accept", "application/json")

		resp, err := client.Do(req)
		if err != nil {
			yield(nil, fmt.Errorf("nodedist: fetch %s: %w", url, err))
			return
		}
		defer resp.Body.Close()

		if resp.StatusCode != http.StatusOK {
			yield(nil, fmt.Errorf("nodedist: fetch %s: %s", url, resp.Status))
			return
		}

		var entries []Entry
		if err := json.NewDecoder(resp.Body).Decode(&entries); err != nil {
			yield(nil, fmt.Errorf("nodedist: decode %s: %w", url, err))
			return
		}

		yield(entries, nil)
	}
}
