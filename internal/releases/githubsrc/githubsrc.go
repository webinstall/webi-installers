// Package githubsrc fetches source archives from GitHub releases.
//
// Some packages (shell scripts, vim plugins) are installed from the
// auto-generated source tarballs rather than uploaded binary assets.
// This package fetches releases and exposes the tarball/zipball URLs.
//
// Use [github] for packages that use uploaded binary assets.
package githubsrc

import (
	"context"
	"iter"
	"net/http"

	"github.com/webinstall/webi-installers/internal/releases/githubish"
)

const baseURL = "https://api.github.com"

// Fetch retrieves releases from GitHub for the given owner/repo.
// Paginates automatically, yielding one batch per API page.
//
// Callers should use [githubish.Release.TarballURL] and
// [githubish.Release.ZipballURL] rather than the Assets list.
func Fetch(ctx context.Context, client *http.Client, owner, repo string, auth *githubish.Auth) iter.Seq2[[]githubish.Release, error] {
	return githubish.Fetch(ctx, client, baseURL, owner, repo, auth)
}
