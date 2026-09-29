// Package nodedist fetches Node.js releases from both official and unofficial
// build sources.
//
// Official builds cover the standard platforms (linux-x64, osx-arm64, win-x64,
// etc.). Unofficial builds add musl, loong64, and other targets that the
// official CI doesn't produce.
//
// Both sources use the same index format, served by [nodeindex].
package nodedist

import (
	"context"
	"iter"
	"net/http"

	"github.com/webinstall/webi-installers/internal/releases/nodeindex"
)

const (
	officialURL   = "https://nodejs.org/download/release"
	unofficialURL = "https://unofficial-builds.nodejs.org/download/release"
)

// Fetch retrieves Node.js releases from both official and unofficial sources.
// Yields one batch per source (official first, then unofficial).
func Fetch(ctx context.Context, client *http.Client) iter.Seq2[[]nodeindex.Entry, error] {
	return func(yield func([]nodeindex.Entry, error) bool) {
		for entries, err := range nodeindex.Fetch(ctx, client, officialURL) {
			if !yield(entries, err) {
				return
			}
		}
		for entries, err := range nodeindex.Fetch(ctx, client, unofficialURL) {
			if !yield(entries, err) {
				return
			}
		}
	}
}
