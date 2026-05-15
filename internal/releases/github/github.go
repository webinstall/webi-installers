// Package github fetches releases from the GitHub API.
//
// This is a thin wrapper around [githubish] that sets the base URL to
// https://api.github.com. Use [githubish] directly for Gitea, Forgejo,
// or other GitHub-compatible forges.
package github

import (
	"context"
	"iter"
	"net/http"

	"github.com/webinstall/webi-installers/internal/releases/githubish"
)

const baseURL = "https://api.github.com"

// Fetch retrieves releases from GitHub for the given owner/repo.
// Paginates automatically, yielding one batch per API page.
func Fetch(ctx context.Context, client *http.Client, owner, repo string, auth *githubish.Auth) iter.Seq2[[]githubish.Release, error] {
	return githubish.Fetch(ctx, client, baseURL, owner, repo, auth)
}
