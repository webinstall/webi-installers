// Package giteasrc fetches source archives from Gitea/Forgejo releases.
//
// Some packages are installed from the auto-generated source tarballs
// rather than uploaded binary assets. This package fetches releases and
// exposes the tarball/zipball URLs.
//
// Use [gitea] for packages that use uploaded binary assets.
package giteasrc

import (
	"context"
	"iter"
	"net/http"

	"github.com/webinstall/webi-installers/internal/releases/gitea"
)

// Fetch retrieves releases from a Gitea instance for the given owner/repo.
// Paginates automatically, yielding one batch per API page.
//
// Callers should use [gitea.Release.TarballURL] and
// [gitea.Release.ZipballURL] rather than the Assets list.
func Fetch(ctx context.Context, client *http.Client, baseURL, owner, repo string, auth *gitea.Auth) iter.Seq2[[]gitea.Release, error] {
	return gitea.Fetch(ctx, client, baseURL, owner, repo, auth)
}
