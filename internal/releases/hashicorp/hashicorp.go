// Package hashicorp fetches release data from the HashiCorp releases API.
//
// HashiCorp publishes release indexes at:
//
//	https://releases.hashicorp.com/{product}/index.json
//
// The response is a JSON object with a "versions" key mapping version strings
// to objects containing build arrays with url, os, arch, and filename.
package hashicorp

import (
	"context"
	"encoding/json"
	"fmt"
	"iter"
	"net/http"
)

// Index is the top-level response from the HashiCorp releases API.
type Index struct {
	Versions map[string]Version `json:"versions"`
}

// Version is one release version with its builds.
type Version struct {
	Name            string  `json:"name"`              // "terraform"
	Version         string  `json:"version"`           // "1.12.0"
	SHASUMS         string  `json:"shasums,omitempty"`  // URL to SHA256SUMS file
	SHASUMSSig      string  `json:"shasums_signature"` // URL to signature
	Builds          []Build `json:"builds"`
	TimestampCreated string `json:"timestamp_created,omitempty"`
	TimestampUpdated string `json:"timestamp_updated,omitempty"`
}

// Build is one downloadable artifact.
type Build struct {
	Name     string `json:"name"`     // "terraform"
	Version  string `json:"version"`  // "1.12.0"
	OS       string `json:"os"`       // "linux", "darwin", "windows"
	Arch     string `json:"arch"`     // "amd64", "arm64", "386"
	Filename string `json:"filename"` // "terraform_1.12.0_linux_amd64.zip"
	URL      string `json:"url"`      // full download URL
}

// Fetch retrieves the HashiCorp release index for a product.
//
// Yields one batch containing all versions.
func Fetch(ctx context.Context, client *http.Client, product string) iter.Seq2[*Index, error] {
	return func(yield func(*Index, error) bool) {
		url := fmt.Sprintf("https://releases.hashicorp.com/%s/index.json", product)

		req, err := http.NewRequestWithContext(ctx, http.MethodGet, url, nil)
		if err != nil {
			yield(nil, fmt.Errorf("hashicorp: %w", err))
			return
		}
		req.Header.Set("Accept", "application/json")

		resp, err := client.Do(req)
		if err != nil {
			yield(nil, fmt.Errorf("hashicorp: fetch %s: %w", product, err))
			return
		}
		defer resp.Body.Close()

		if resp.StatusCode != http.StatusOK {
			yield(nil, fmt.Errorf("hashicorp: fetch %s: %s", product, resp.Status))
			return
		}

		var idx Index
		if err := json.NewDecoder(resp.Body).Decode(&idx); err != nil {
			yield(nil, fmt.Errorf("hashicorp: decode %s: %w", product, err))
			return
		}

		yield(&idx, nil)
	}
}
