// Package gitlabsrc fetches source archives from GitLab releases.
//
// Some packages are installed from the auto-generated source archives
// rather than attached binary links. This package fetches releases and
// exposes the source archive URLs.
//
// Use [gitlab] for packages that use attached release links (binaries).
package gitlabsrc

import (
	"context"
	"iter"
	"net/http"

	"github.com/webinstall/webi-installers/internal/releases/gitlab"
)

// Fetch retrieves releases from a GitLab instance.
// Paginates automatically, yielding one batch per API page.
//
// Callers should use [gitlab.Release.Assets.Sources] rather than
// [gitlab.Release.Assets.Links].
func Fetch(ctx context.Context, client *http.Client, baseURL, project string, auth *gitlab.Auth) iter.Seq2[[]gitlab.Release, error] {
	return gitlab.Fetch(ctx, client, baseURL, project, auth)
}
