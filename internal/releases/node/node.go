// Package node fetches Node.js releases from both official and unofficial
// build sources.
//
// Official builds cover the standard platforms (linux-x64, osx-arm64, win-x64,
// etc.). Unofficial builds add musl, loong64, and other targets that the
// official CI doesn't produce.
//
// Both sources use the same index format, served by [nodedist].
package nodedist

import (
	"context"
	"iter"
	"net/http"

	"github.com/webinstall/webi-installers/internal/releases/nodedist"
)

const (
	officialURL   = "https://nodejs.org/download/release"
	unofficialURL = "https://unofficial-builds.nodejs.org/download/release"
)

// Fetch retrieves Node.js releases from both official and unofficial sources.
// Yields one batch per source (official first, then unofficial).
func Fetch(ctx context.Context, client *http.Client) iter.Seq2[[]nodedist.Entry, error] {
	return func(yield func([]nodedist.Entry, error) bool) {
		for entries, err := range nodedist.Fetch(ctx, client, officialURL) {
			if !yield(entries, err) {
				return
			}
		}
		for entries, err := range nodedist.Fetch(ctx, client, unofficialURL) {
			if !yield(entries, err) {
				return
			}
		}
	}
}
